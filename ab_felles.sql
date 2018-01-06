CREATE OR REPLACE PACKAGE AB_FELLES
/*-----------------------------------------------------------------------------
 Navn
    AB_FELLES
--------------------------------------------------------------------------------
 Beskrivelse
    Pakken inneholder fellestjenester for avgiftsberegning.
 Logg
    04-MAR-1999  Anders Blehr    - Opprettet.
    04-MAR-1999  Anders Blehr    - AA0_TJ_01 p�begynt.
    16-APR-1999  Anders Blehr    - AA0_TJ_01 hovedsakelig ferdigprogrammert.
    16-APR-1999  Anders Blehr    - AA0_TJ_02 p�begynt.
    23-APR-1999  Anders Blehr    - AA0_TJ_02 hovedsakelig ferdigprogrammert.
    04-MAI-1999  Anders Blehr    - AA0_TJ_01 og AA0_TJ_02 ferdigprogrammert.
    05-MAI-1999  Anders Blehr    - Regelmatchingslogikken fra AA0_TJ_01 skilt
                                   ut som egen tjeneste, AA0_TJ_03.
    14-MAI-1999  Anders Blehr    - AA0-tjenestene gjennomg�tt og verifisert
-----------------------------------------------------------------------------*/
IS
   -- Avgiftsberegningstjenester
   PROCEDURE AA0_TJ_01 ( f_flybevegelse_id    IN  AB_FLYBEVEGELSER.AB_FLYBEVEGELSE_ID%TYPE  );
   PROCEDURE AA0_TJ_02 ( f_flybevegelse_id    IN  AB_FLYBEVEGELSER.AB_FLYBEVEGELSE_ID%TYPE  );
   FUNCTION  AA0_TJ_03 ( f_denne_regel        IN  AB_REGLER.AB_REGEL_ID%TYPE,
                         f_flybevegelse_id    IN  AB_FLYBEVEGELSER.AB_FLYBEVEGELSE_ID%TYPE,
                         b_beregn_delavgift   IN  BOOLEAN                                   ) RETURN BOOLEAN;

END AB_FELLES;
/


CREATE OR REPLACE PACKAGE BODY AB_FELLES
IS

/*-----------------------------------------------------------------------------
 Tjeneste
    AA0_TJ_01
-------------------------------------------------------------------------------
 Beskrivelse
    Tjenesten finner frem til regler og avtaler som er gyldige for en
    flybevegelse og beregner delavgifter for den.  Delavgifter er
    enkeltavgifter som til sammen utgj�r totalavgiften for ett avgiftsomr�de
    for �n flybevegelse.  Delavgiftene legges inn i tabellen AB_DELAVGIFTER.
 Parametere
    Flybevegelses-ID
 Returverdier
    Ingen
 Logg
    04-MAR-1999  Anders Blehr    - Opprettet
    30-APR-1999  Anders Blehr    - Hovedsakelig ferdigprogrammert
    04-MAI-1999  Anders Blehr    - Ferdigprogrammert
    05-MAI-1999  Anders Blehr    - Regelmatchingslogikken skilt ut som egen
                                   tjeneste AA0-TJ-03
-----------------------------------------------------------------------------*/
PROCEDURE AA0_TJ_01 ( f_flybevegelse_id IN  AB_FLYBEVEGELSER.AB_FLYBEVEGELSE_ID%TYPE )
IS
   e_ferdig                      EXCEPTION;

   CURSOR m_avgiftsomraader IS
      SELECT   AB_AVGIFTSOMRAADE_ID
      FROM     AB_AVGIFTSOMRAADER
      ORDER BY AB_TRAVERSERINGSSEKVENS_N;
-----------------------------------------------------------------------------
-- HentNesteSteg
-----------------------------------------------------------------------------
-- Funksjonen henter neste avgiftsberegningssteg gitt innev�rende steg og
-- tilslagsstatus (hvorvidt det ble funnet en regel for innev�rende steg som
-- "slo til" for flybevegelsen).
-----------------------------------------------------------------------------
FUNCTION HentNesteSteg ( r_dette_steg IN  AB_AVGIFTSBEREGNINGSSTEG%ROWTYPE,
                         b_tilslag    IN  BOOLEAN                           )
RETURN
   AB_AVGIFTSBEREGNINGSSTEG%ROWTYPE
IS
   f_neste_stegnummer            AB_AVGIFTSBEREGNINGSSTEG.AB_DETTE_STEG_N%TYPE;
   r_neste_steg                  AB_AVGIFTSBEREGNINGSSTEG%ROWTYPE;

BEGIN
   Zt.Trace ( 'AA0_TJ_01', 'HentNesteSteg: Start' );

   -- Hent stegnummer for neste steg
   IF ( b_tilslag ) THEN
      f_neste_stegnummer := r_dette_steg.AB_REF_NESTE_STEG_TREFF_N;
   ELSE
      f_neste_stegnummer := r_dette_steg.AB_REF_NESTE_STEG_BOM_N;
   END IF;

   IF ( f_neste_stegnummer < K_AB.STEGNUMMER_SLUTT ) THEN
      -- Hent neste steg basert p� stegnummer for neste steg
      SELECT   *
      INTO     r_neste_steg
      FROM     AB_AVGIFTSBEREGNINGSSTEG
      WHERE    AB_AVGIFTSOMRAADE_ID   = r_dette_steg.AB_AVGIFTSOMRAADE_ID
         AND   AB_OVERORDNET_NODE_VCH = r_dette_steg.AB_OVERORDNET_NODE_VCH
         AND   AB_DETTE_STEG_N        = f_neste_stegnummer;
   ELSE
      r_neste_steg.AB_DETTE_STEG_N := f_neste_stegnummer;
   END IF;

   Zt.Trace ( 'AA0_TJ_01', 'HentNesteSteg: Stopp' );

   RETURN r_neste_steg;

EXCEPTION
   WHEN NO_DATA_FOUND THEN
      Zt.Trace ( 'AA0_TJ_01', 'HentNesteSteg: Exception' );
      ZtErr.SetError ( 'AA0_TJ_01', E_AVG.NESTE_STEG_MANGLER, '[HentNesteSteg] Avgiftsomr�de ' || r_dette_steg.AB_AVGIFTSOMRAADE_ID ||
                       ', node ' || r_dette_steg.AB_DENNE_NODE_ID || '.');
   WHEN TOO_MANY_ROWS THEN
      Zt.Trace ( 'AA0_TJ_01', 'HentNesteSteg: Exception' );
      ZtErr.SetError ( 'AA0_TJ_01', E_AVG.NESTE_STEG_IKKE_ENTYDIG, '[HentNesteSteg] Avgiftsomr�de ' || r_dette_steg.AB_AVGIFTSOMRAADE_ID ||
                       ', node ' || r_dette_steg.AB_DENNE_NODE_ID || '.');
   WHEN OTHERS THEN
      Zt.Trace ( 'AA0_TJ_01', 'HentNesteSteg: Exception' );
      ZtErr.SetError ( 'AA0_TJ_01', E_AVG.ANNEN_FEIL, '[HentNesteSteg] ' || SQLERRM || '.  Avgiftsomr�de ' || r_dette_steg.AB_AVGIFTSOMRAADE_ID ||
                       ', node ' || r_dette_steg.AB_DENNE_NODE_ID || '.');
END HentNesteSteg;


-----------------------------------------------------------------------------
-- FinnOgMatchRegler
-----------------------------------------------------------------------------
-- Prosedyren finner og matcher alle regler p� innev�rende niv� i regel-
-- hierarkiet, iht. traverseringssekvensen angitt i AB_AVGIFTSBEREGNINGSSTEG.
-- For hver regel som matcher, kaller prosedyren seg selv rekursivt for �
-- finne og matche evt. regler som er underordnet denne regelen.
-----------------------------------------------------------------------------
PROCEDURE FinnOgMatchRegler ( f_avgiftsomraade   IN  AB_AVGIFTSOMRAADER.AB_AVGIFTSOMRAADE_ID%TYPE,
                              f_overordnet_node  IN  AB_AVGIFTSBEREGNINGSSTEG.AB_OVERORDNET_NODE_VCH%TYPE,
                              f_overordnet_regel IN  AB_REGLER.AB_REGEL_ID%TYPE,
                              f_flybevegelse_id  IN  AB_FLYBEVEGELSER.AB_FLYBEVEGELSE_ID%TYPE              )
IS
   r_dette_steg                  AB_AVGIFTSBEREGNINGSSTEG%ROWTYPE;
   f_denne_regel                 AB_REGLER.AB_REGEL_ID%TYPE;
   f_match_alle                  AB_TYPER_REGLER.AB_MATCH_ALLE_C%TYPE;
   b_match                       BOOLEAN := FALSE;
   e_ukjent_returkode            EXCEPTION;

   CURSOR m_regler IS
      SELECT   a.AB_REGEL_ID
      FROM     AB_REGLER a,
               AB_REL_REGLER_REGLER b
      WHERE    a.AB_KATEGORI_VCH      = r_dette_steg.AB_DENNE_REGELKATEGORI_VCH
         AND   a.AB_TYPE_ID           = r_dette_steg.AB_TYPE_ID
         AND   a.AB_AVGIFTSOMRAADE_ID = f_avgiftsomraade
         AND   a.AB_REGEL_ID          = b.AB_REGEL_ID_ER_UNDERORDNET
         AND   b.AB_REGEL_ID          = f_overordnet_regel
      ORDER BY a.AB_REGEL_ID;

BEGIN
   Zt.Trace ( 'AA0_TJ_01', 'FinnOgMatchRegler: Start' );

   -- Hent f�rste avgiftsberegningssteg p� dette niv�
   SELECT   *
   INTO     r_dette_steg
   FROM     AB_AVGIFTSBEREGNINGSSTEG
   WHERE    AB_AVGIFTSOMRAADE_ID   = f_avgiftsomraade
      AND   AB_OVERORDNET_NODE_VCH = f_overordnet_node
      AND   AB_DETTE_STEG_N        = 1;

   -- Finn og match regler for hvert avgiftsberegningssteg
   WHILE ( TRUE ) LOOP
      -- Initialiser match-flagget til FALSE
      b_match := FALSE;

      -- Hent flagg som indikerer hvorvidt alle eller kun f�rste regel som matcher skal behandles
      SELECT   AB_MATCH_ALLE_C
      INTO     f_match_alle
      FROM     AB_TYPER_REGLER
      WHERE    AB_TYPE_ID = r_dette_steg.AB_TYPE_ID;

      -- Finn og match regler
      FOR r_regel IN m_regler LOOP
         IF ( AB_FELLES.AA0_TJ_03 ( r_regel.AB_REGEL_ID, f_flybevegelse_id, TRUE ) ) THEN
            -- Finn og match underordnede regler dersom denne regelen matchet
            FinnOgMatchRegler ( f_avgiftsomraade, r_dette_steg.AB_DENNE_NODE_ID, r_regel.AB_REGEL_ID, f_flybevegelse_id );

            -- Regelen matchet
            b_match := TRUE;

            -- Hopp ut av l�kken dersom kun �n regel skal matches eller vi har en Oops-returkode...
            EXIT WHEN ( f_match_alle = K_AB.INDIKATOR_JANEI_NEI );
         END IF;
      END LOOP;

      -- Hent neste avgiftsberegningssteg
      r_dette_steg := HentNesteSteg ( r_dette_steg, b_match );

      -- H�ndter stegnummer som representerer retur-/feilkoder
      IF ( r_dette_steg.AB_DETTE_STEG_N > K_AB.STEGNUMMER_SLUTT ) THEN
         IF ( r_dette_steg.AB_DETTE_STEG_N = K_AB.RETURKODE_NIVAA_FERDIG ) THEN
            EXIT;                  -- Ferdig p� dette niv�
         ELSIF ( r_dette_steg.AB_DETTE_STEG_N = K_AB.RETURKODE_FERDIG ) THEN
            RAISE e_ferdig;        -- Flybevegelsen er ferdigbehandlet, avslutt
         ELSE
            RAISE e_ukjent_returkode;   -- B�r ikke skje...
         END IF;
      END IF;

   END LOOP;

   Zt.Trace ( 'AA0_TJ_01', 'FinnOgMatchRegler: Stopp' );

EXCEPTION
   WHEN e_ferdig THEN
      Zt.Trace ( 'AA0_TJ_01', 'FinnOgMatchRegler: Ferdig (Neste steg = K_AB.RETURKODE_FERDIG (' || TO_CHAR ( K_AB.RETURKODE_FERDIG ) || ')).' );
      RAISE e_ferdig;
   WHEN NO_DATA_FOUND THEN
      -- NO_DATA_FOUND betyr at det ikke finnes avgiftsberegningssteg p� dette niv�; det er helt OK...
      Zt.Trace ( 'AA0_TJ_01', 'FinnOgMatchRegler: Ferdig (NO_DATA_FOUND).' );
      NULL;
   WHEN e_ukjent_returkode THEN
      Zt.Trace ( 'AA0_TJ_01', 'FinnOgMatchRegler: Exception' );
      ZtErr.SetError ( 'AA0_TJ_01', E_AVG.UKJENT_RETURKODE, '[FinnOgMatchRegler] Returkode (stegnummer) '
                       || TO_CHAR ( r_dette_steg.AB_DETTE_STEG_N ) || '.' );
   WHEN OTHERS THEN
      Zt.Trace ( 'AA0_TJ_01', 'FinnOgMatchRegler: Exception' );
      ZtErr.SetError ( 'AA0_TJ_01', E_AVG.ANNEN_FEIL, '[FinnOgMatchRegler] ' || SQLERRM || '.  Flybevegelses-ID '
                       || TO_CHAR ( f_flybevegelse_id ) || ', avgiftsomr�de ' || f_avgiftsomraade || '.' );
END FinnOgMatchRegler;


-----------------------------------------------------------------------------
-- AA0_TJ_01
-----------------------------------------------------------------------------
-- Hovedl�kke
-----------------------------------------------------------------------------
BEGIN
   Zt.Trace ( 'AA0_TJ_01', 'AA0_TJ_01: Start' );

   FOR r_avgiftsomraade IN m_avgiftsomraader LOOP
      -- Finn og match regler for dette avgiftsomraade
      FinnOgMatchRegler ( r_avgiftsomraade.AB_AVGIFTSOMRAADE_ID, K_AB.NODE_NULLNODE, K_AB.ID_REGEL_NULLREGEL, f_flybevegelse_id );
   END LOOP;

   Zt.Trace ( 'AA0_TJ_01', 'AA0_TJ_01: Stopp' );
EXCEPTION
   WHEN e_ferdig THEN
      Zt.Trace ( 'AA0_TJ_01', 'AA0_TJ_01: Ferdig-exception' );
   WHEN OTHERS THEN
      Zt.Trace ( 'AA0_TJ_01', 'AA0_TJ_01: Exception' );
      ZtErr.SetError ( 'AA0_TJ_01', E_AVG.ANNEN_FEIL, '[Hovedl�kke] ' || SQLERRM || '.' );
END AA0_TJ_01;


/*-----------------------------------------------------------------------------
 Tjeneste
    AA0_TJ_02
-------------------------------------------------------------------------------
 Beskrivelse
    Tjenesten summerer delavgifter og lagrer avgiftslinjer for en gitt
    flybevegelse med utgangspunkt i delavgifter som er beregnet med grunnlag i
    regel- og avtaleverket (gj�res av tjeneste AA0-TJ-01).  For allerede
    fakturerte avgifter opprettes kreditlinjer i tillegg til nye avgiftslinjer.
    For flybevegelser som helt eller delvis fritas for avgifter, settes riktig
    fritakskode.
 Parametere
    Flybevegelses-ID
 Returverdier
    Ingen
 Logg
    16-APR-1999  Anders Blehr    - Opprettet
    30-APR-1999  Anders Blehr    - Hovedsakelig ferdigprogrammert
    04-MAI-1999  Anders Blehr    - Ferdigprogrammert
-----------------------------------------------------------------------------*/
PROCEDURE AA0_TJ_02 ( f_flybevegelse_id IN  AB_FLYBEVEGELSER.AB_FLYBEVEGELSE_ID%TYPE )
IS
   r_avgiftslinje                AB_AVGIFTSLINJER%ROWTYPE;
   b_avgift_beregnet             BOOLEAN := FALSE;

   CURSOR m_avgiftsomraader IS
      SELECT   AB_AVGIFTSOMRAADE_ID
      FROM     AB_AVGIFTSOMRAADER
      ORDER BY AB_TRAVERSERINGSSEKVENS_N;


-----------------------------------------------------------------------------
-- GenereltFritatt
-----------------------------------------------------------------------------
-- Funksjonen unders�ker om flybevegelsen er generelt fritatt for avgifter.
-- I s� fall settes den korrekte fritakskoden for flybevegelsen.  Funksjonen
-- returnerer TRUE om flybevegelsen er fritatt og FALSE ellers.
-----------------------------------------------------------------------------
FUNCTION GenereltFritatt ( f_flybevegelse_id IN  AB_FLYBEVEGELSER.AB_FLYBEVEGELSE_ID%TYPE )
RETURN
   BOOLEAN
IS
   r_fritakslinje                AB_DELAVGIFTER%ROWTYPE;
   f_fritakslinje_id             AB_DELAVGIFTER.AB_DELAVGIFT_ID%TYPE;
   f_fritakskode                 AB_FRITAKSKODER.AB_FRITAKSKODE_ID%TYPE;
   f_regel_id                    AB_REGLER.AB_REGEL_ID%TYPE;
   b_generelt_fritatt            BOOLEAN := TRUE;
   b_kun_en_delavgiftslinje      BOOLEAN := TRUE;
   b_fritatt_med_kort            BOOLEAN := TRUE;
   e_mer_enn_ett_generelt_fritak EXCEPTION;
   e_fritakskode_mangler         EXCEPTION;

BEGIN
   Zt.Trace ( 'AA0_TJ_02', 'GenereltFritatt: Start' );

   BEGIN
      SELECT   a.AB_DELAVGIFT_ID,
               b.AB_FRITAKSKODE_ID,
               b.AB_REGEL_ID
      INTO     f_fritakslinje_id,
               f_fritakskode,
               f_regel_id
      FROM     AB_DELAVGIFTER a,
               AB_REGLER b
      WHERE    a.AB_FLYBEVEGELSE_ID    = f_flybevegelse_id
         AND   a.AB_AVGIFTSOMRAADE_ID  = K_AB.AVGOMRAADE_GENERELT
         AND   a.AB_BEHANDLET_C        = K_AB.INDIKATOR_JANEI_NEI
         AND   a.AB_BEREGNINGSMAATE_ID = K_AB.BERMAATE_FRITAK
         AND   b.AB_REGEL_ID           = a.AB_REGEL_ID;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         -- Ingen fritakslinjer funnet, flybevegelsen er ikke fritatt
         b_generelt_fritatt := FALSE;
      WHEN TOO_MANY_ROWS THEN
         RAISE e_mer_enn_ett_generelt_fritak;
   END;

   IF ( b_generelt_fritatt ) THEN
      IF ( f_fritakskode IS NULL ) THEN
         RAISE e_fritakskode_mangler;
      ELSE
         -- Sett generell fritakskode for flybevegelsen
         UPDATE   AB_FLYBEVEGELSER
         SET      AB_FRITAKSKODE_ID  = f_fritakskode
         WHERE    AB_FLYBEVEGELSE_ID = f_flybevegelse_id;
         -- Sett fritakslinjen til "Behandlet"
         UPDATE   AB_DELAVGIFTER
         SET      AB_BEHANDLET_C  = K_AB.INDIKATOR_JANEI_JA
         WHERE    AB_DELAVGIFT_ID = f_fritakslinje_id;
      END IF;
   ELSE
      -- Vurder om flybevegelsen er fritatt pga. �rs- eller ukekort; i s� fall
      -- skal det kun finnes �n delavgiftslinje p� flybevegelsen ... [forts.]
      BEGIN
         SELECT   a.AB_DELAVGIFT_ID,
                  b.AB_FRITAKSKODE_ID
         INTO     f_fritakslinje_id,
                  f_fritakskode
         FROM     AB_DELAVGIFTER a,
                  AB_REGLER b
         WHERE    a.AB_FLYBEVEGELSE_ID   = f_flybevegelse_id
            AND   a.AB_BEHANDLET_C       = K_AB.INDIKATOR_JANEI_NEI
            AND   b.AB_REGEL_ID          = a.AB_REGEL_ID;

      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            b_kun_en_delavgiftslinje := FALSE;
         WHEN TOO_MANY_ROWS THEN
            b_kun_en_delavgiftslinje := FALSE;
      END;

      -- [forts.] ... og denne skal ha knyttet til seg �n av fritakskodene "�rskort" og "Ukekort".
      IF ( b_kun_en_delavgiftslinje AND ( f_fritakskode IN ( K_AB.FRITAKSKODE_AARSKORT, K_AB.FRITAKSKODE_UKEKORT ) ) ) THEN
         -- Sett fritakskode for flybevegelsen
         UPDATE   AB_FLYBEVEGELSER
         SET      AB_FRITAKSKODE_ID  = f_fritakskode
         WHERE    AB_FLYBEVEGELSE_ID = f_flybevegelse_id;

         -- Sett fritakslinjen til "Behandlet"
         UPDATE   AB_DELAVGIFTER
         SET      AB_BEHANDLET_C  = K_AB.INDIKATOR_JANEI_JA
         WHERE    AB_DELAVGIFT_ID = f_fritakslinje_id;

         -- Flybevegelsen ble generelt fritatt likevel...
         b_generelt_fritatt := TRUE;
      END IF;
   END IF;

   Zt.Trace ( 'AA0_TJ_02', 'GenereltFritatt: Stopp' );

   RETURN b_generelt_fritatt;

EXCEPTION
   WHEN e_mer_enn_ett_generelt_fritak THEN
      Zt.Trace ( 'AA0_TJ_02', 'GenereltFritatt: Exception' );
      ZtErr.SetError ( 'AA0_TJ_02', E_AVG.MER_ENN_ETT_GENERELT_FRITAK, '[GenereltFritatt] Flybevegelses-ID = ' || TO_CHAR ( f_flybevegelse_id ) || '.' );
   WHEN e_fritakskode_mangler THEN
      Zt.Trace ( 'AA0_TJ_02', 'GenereltFritatt: Exception' );
      ZtErr.SetError ( 'AA0_TJ_02', E_AVG.FRITAKSKODE_MANGLER, '[GenereltFritatt] Regel-ID = ' || TO_CHAR ( f_regel_id ) || '.' );
   WHEN OTHERS THEN
      Zt.Trace ( 'AA0_TJ_02', 'GenereltFritatt: Exception' );
      ZtErr.SetError ( 'AA0_TJ_02', E_AVG.ANNEN_FEIL, SQLERRM || '.  [GenereltFritatt] Flybevegelses-ID = ' || TO_CHAR ( f_flybevegelse_id ) || '.' );
END GenereltFritatt;


-----------------------------------------------------------------------------
-- SummerDelavgifter
-----------------------------------------------------------------------------
-- Funksjonen summerer sammen delavgifter pr. for ett avgiftsomr�de.  For
-- hver delavgiftslinje kaller funksjonen seg selv rekursivt for � beregne
-- summen av delavgiftene som er generert av regler underordnet regelen som
-- har generert innev�rende delavgift.  Endelige brutto- og nettoavgifter p�
-- innev�rende niv� beregnes ut fra angitte beregnings- og summeringsm�ter.
-----------------------------------------------------------------------------
FUNCTION SummerDelavgifter ( f_overordnet_regel IN     AB_REGLER.AB_REGEL_ID%TYPE,
                             f_delavgift        IN     AB_DELAVGIFTER.AB_DELAVGIFT_N%TYPE,
                             r_avgiftslinje     IN     AB_AVGIFTSLINJER%ROWTYPE,
                             f_bruttoavgift     IN OUT AB_AVGIFTSLINJER.AB_BELOEP_BRUTTO_N%TYPE )
RETURN
   AB_AVGIFTSLINJER.AB_BELOEP_BRUTTO_N%TYPE
IS
   f_akkumulert_bruttosum        AB_AVGIFTSLINJER.AB_BELOEP_BRUTTO_N%TYPE;
   f_akkumulert_nettosum         AB_AVGIFTSLINJER.AB_BELOEP_NETTO_N%TYPE;
   f_underordnet_bruttosum       AB_AVGIFTSLINJER.AB_BELOEP_BRUTTO_N%TYPE;
   f_underordnet_nettosum        AB_AVGIFTSLINJER.AB_BELOEP_NETTO_N%TYPE;
   f_bruttosum                   AB_AVGIFTSLINJER.AB_BELOEP_BRUTTO_N%TYPE;
   f_nettosum                    AB_AVGIFTSLINJER.AB_BELOEP_NETTO_N%TYPE;

   CURSOR m_delavgifter IS
      SELECT   a.*
      FROM     AB_DELAVGIFTER a,
               AB_REL_REGLER_REGLER b
      WHERE    a.AB_FLYBEVEGELSE_ID   = r_avgiftslinje.AB_FLYBEVEGELSE_ID
         AND   a.AB_AVGIFTSOMRAADE_ID = r_avgiftslinje.AB_AVGIFTSOMRAADE_ID
         AND   a.AB_BEHANDLET_C       = K_AB.INDIKATOR_JANEI_NEI
         AND   a.AB_REGEL_ID          = b.AB_REGEL_ID_ER_UNDERORDNET
         AND   b.AB_REGEL_ID          = f_overordnet_regel
      ORDER BY a.AB_DELAVGIFT_ID;

BEGIN
   Zt.Trace ( 'AA0_TJ_02', 'SummerDelavgifter: Start' );

   -- Setter akkumulert brutto- og nettosummer lik delavgift fra innev�rende delavgiftslinje
   f_akkumulert_bruttosum := f_delavgift;
   f_akkumulert_nettosum  := f_delavgift;

   FOR r_delavgift IN m_delavgifter LOOP
      -- Henter underordnet sats/sum fra underordnede delavgiftslinjer
      f_underordnet_nettosum := SummerDelavgifter ( r_delavgift.AB_REGEL_ID, r_delavgift.AB_DELAVGIFT_N, r_avgiftslinje, f_underordnet_bruttosum );

      IF ( r_delavgift.AB_BEREGNINGSMAATE_ID = K_AB.BERMAATE_PROSENTSATS ) THEN
         -- Beregner delsum som prosentdel av akkumulert sum
         f_bruttosum := f_akkumulert_bruttosum * ( f_underordnet_bruttosum / 100 );
         f_nettosum  := f_akkumulert_nettosum  * ( f_underordnet_nettosum  / 100 );
      ELSIF ( r_delavgift.AB_BEREGNINGSMAATE_ID = K_AB.BERMAATE_MIMIMUMSSATS ) THEN
         IF ( f_underordnet_nettosum > f_akkumulert_nettosum ) THEN
            -- Setter akkumulerte summer til 0 og summer p� dette niv� til minimumssats dersom akkumulert sum er mindre enn minimumssatsen
            f_bruttosum            := f_underordnet_bruttosum;
            f_nettosum             := f_underordnet_nettosum;
            f_akkumulert_bruttosum := 0;
            f_akkumulert_nettosum  := 0;
         END IF;
      ELSE
         -- Setter brutto- og nettosum lik underordnede brutto- og nettosum
         f_bruttosum := f_underordnet_bruttosum;
         f_nettosum  := f_underordnet_nettosum;
      END IF;

      IF ( r_delavgift.AB_BEREGNINGSMAATE_ID = K_AB.BERMAATE_MIMIMUMSSATS ) THEN
         -- Ved minimumssats skal ikke akkumulerte summer summeres ytterligere
         NULL;
      ELSIF ( r_delavgift.AB_SUMMERINGSMAATE_C = K_AB.SUMMERINGSMAATE_PLUSS ) THEN
         -- Legger brutto- og nettosum til akkumulert brutto- og nettosum n�r summeringsm�ten er 'pluss'
         f_akkumulert_bruttosum := f_akkumulert_bruttosum + f_bruttosum;
         f_akkumulert_nettosum  := f_akkumulert_nettosum  + f_nettosum;
      ELSE
         -- Trekker nettosum fra akkumulert nettosum n�r summeringsm�ten er 'minus'
         f_akkumulert_nettosum := f_akkumulert_nettosum - f_nettosum;
      END IF;
   END LOOP;

   Zt.Trace ( 'AA0_TJ_02', 'SummerDelavgifter: Stopp' );

   -- Returnerer nye akkumulerte brutto- og nettosummer
   f_bruttoavgift := f_akkumulert_bruttosum;
   RETURN f_akkumulert_nettosum;

EXCEPTION
   WHEN OTHERS THEN
      Zt.Trace ( 'AA0_TJ_02', 'SummerDelavgifter: Exception' );
      ZtErr.SetError ( 'AA0_TJ_02', E_AVG.FEIL_VED_SUMMERING, '[SummerDelavgifter] ' || SQLERRM || '.  Avgiftslinje-ID ' ||
                       TO_CHAR ( r_avgiftslinje.AB_AVGIFTSLINJE_ID_N ) || '.' );
END SummerDelavgifter;


-----------------------------------------------------------------------------
-- KreditlinjeSkalOpprettes
-----------------------------------------------------------------------------
-- Funksjonen utleder hvorvidt det skal opprettes en kreditlinje motsvarende
-- en allerede eksisterende avgiftslinje for avgiften, slik at kunden f�r en
-- kreditnota p� innbetalt bel�p.  Dette skal gj�res dersom 1) reberegnet
-- avgift avviker fra tidligere beregnet avgift; 2) fakturerende enhet er en
-- annen enn tidligere utledet; eller 3) kunden er en annen enn ved forrige
-- beregning.
-----------------------------------------------------------------------------
FUNCTION KreditlinjeSkalOpprettes ( r_ny_avgiftslinje     IN  AB_AVGIFTSLINJER%ROWTYPE,
                                    r_gammel_avgiftslinje IN  AB_AVGIFTSLINJER%ROWTYPE  )
RETURN
   BOOLEAN
IS
   r_gammel_flybevegelse         AB_AVGIFTSLINJEGRUNNLAG%ROWTYPE;
   r_ny_flybevegelse             AB_FLYBEVEGELSER%ROWTYPE;
   f_gammel_kunde                AB_AVGIFTSLINJEGRUNNLAG.AB_KUNDE_ID_DEP_N%TYPE;
   f_ny_kunde                    AB_FLYBEVEGELSER.AB_KUNDE_ID_DEP_N%TYPE;
   e_fakturasted_eier_ikke_fb    EXCEPTION;

BEGIN
   Zt.Trace ( 'AA0_TJ_02', 'KreditlinjeSkalOpprettes: Start' );

   -- Hent flybevegelsen som ligger til grunn for den gamle avgiftslinjen
   SELECT   *
   INTO     r_gammel_flybevegelse
   FROM     AB_AVGIFTSLINJEGRUNNLAG
   WHERE    AB_FLYBEVEGELSE_ID     = r_gammel_avgiftslinje.AB_FLYBEVEGELSE_ID_HAR
      AND   AB_REGISTRERINGSDATO_D = r_gammel_avgiftslinje.AB_REGISTRERINGSDATO_D_HAR;

   -- Hent flybevegelsen som ligger til grunn for den nye avgiftslinjen
   SELECT   *
   INTO     r_ny_flybevegelse
   FROM     AB_FLYBEVEGELSER
   WHERE    AB_FLYBEVEGELSE_ID = r_ny_avgiftslinje.AB_FLYBEVEGELSE_ID;

   -- Hent kunde-ID for kunden knyttet til den gamle avgiftslinjen
   IF ( r_gammel_avgiftslinje.AB_FAKTURASTED_ID = r_gammel_flybevegelse.AB_FAKTURASTED_DEP_VCH ) THEN
      f_gammel_kunde := r_gammel_flybevegelse.AB_KUNDE_ID_DEP_N;
   ELSIF ( r_gammel_avgiftslinje.AB_FAKTURASTED_ID = r_gammel_flybevegelse.AB_FAKTURASTED_ARR_VCH ) THEN
      f_gammel_kunde := r_gammel_flybevegelse.AB_KUNDE_ID_ARR_N;
   ELSE
      RAISE e_fakturasted_eier_ikke_fb;
   END IF;

   -- Hent kunde-ID for kunden knyttet til den nye avgiftslinjen
   IF ( r_ny_avgiftslinje.AB_FAKTURASTED_ID = r_ny_flybevegelse.AB_FAKTURASTED_ID ) THEN
      f_ny_kunde := r_ny_flybevegelse.AB_KUNDE_ID_DEP_N;
   ELSIF ( r_ny_avgiftslinje.AB_FAKTURASTED_ID = r_ny_flybevegelse.AB_FAKTURASTED_ID_ARR_FAKTURER ) THEN
      f_ny_kunde := r_ny_flybevegelse.AB_KUNDE_ID_ARR_N;
   ELSE
      RAISE e_fakturasted_eier_ikke_fb;
   END IF;

   -- Kreditlinje skal opprettes dersom bel�p, fakturasted eller kunde-ID er endret
   RETURN ( ( r_ny_avgiftslinje.AB_BELOEP_NETTO_N != r_gammel_avgiftslinje.AB_BELOEP_NETTO_N ) OR
            ( r_ny_avgiftslinje.AB_FAKTURASTED_ID != r_gammel_avgiftslinje.AB_FAKTURASTED_ID ) OR
            ( f_ny_kunde                          != f_gammel_kunde                          )    );

   Zt.Trace ( 'AA0_TJ_02', 'KreditlinjeSkalOpprettes: Stopp' );

EXCEPTION
   WHEN e_fakturasted_eier_ikke_fb THEN
      Zt.Trace ( 'AA0_TJ_02', 'KreditlinjeSkalOpprettes: Exception' );
      ZtErr.SetError ( 'AA0_TJ_02', E_AVG.FAKTURASTED_EIER_IKKE_FB, '[KreditlinjeSkalOpprettes] Flybevegelses-ID ' ||
                       TO_CHAR ( r_ny_avgiftslinje.AB_FLYBEVEGELSE_ID ) || ', eksisterende avgiftslinje ' ||
                       TO_CHAR ( r_gammel_avgiftslinje.AB_AVGIFTSLINJE_ID_N ) || '.' );
   WHEN NO_DATA_FOUND THEN
      Zt.Trace ( 'AA0_TJ_02', 'KreditlinjeSkalOpprettes: Exception' );
      ZtErr.SetError ( 'AA0_TJ_02', E_AVG.FLYBEV_EL_AVG_L_GRLAG_MANGLER, '[KreditlinjeSkalOpprettes] Flybevegelses-ID ' ||
                       TO_CHAR ( r_ny_avgiftslinje.AB_FLYBEVEGELSE_ID ) || ', prim�rn�kkel for avgiftslinjegrunnlag ' ||
                       TO_CHAR ( r_gammel_avgiftslinje.AB_FLYBEVEGELSE_ID_HAR ) || ' + ' ||
                       TO_CHAR ( r_gammel_avgiftslinje.AB_REGISTRERINGSDATO_D_HAR, K_AB.FORMAT_DATE_TIME ) || '.' );
   WHEN OTHERS THEN
      Zt.Trace ( 'AA0_TJ_02', 'KreditlinjeSkalOpprettes: Exception' );
      ZtErr.SetError ( 'AA0_TJ_02', E_AVG.ANNEN_FEIL, '[KreditlinjeSkalOpprettes] ' || SQLERRM || '.  Flybevegelses-ID ' ||
                       TO_CHAR ( r_ny_avgiftslinje.AB_FLYBEVEGELSE_ID ) || ', prim�rn�kkel for avgiftslinjegrunnlag ' ||
                       TO_CHAR ( r_gammel_avgiftslinje.AB_FLYBEVEGELSE_ID_HAR ) || ' + ' ||
                       TO_CHAR ( r_gammel_avgiftslinje.AB_REGISTRERINGSDATO_D_HAR, K_AB.FORMAT_DATE_TIME ) || '.' );
END KreditlinjeSkalOpprettes;


-----------------------------------------------------------------------------
-- OpprettKreditlinje
-----------------------------------------------------------------------------
-- Prosedyren oppretter en kreditlinje motsvarende avgiftslinjen som mottas
-- som parameter.  Brutto- og nettobel�pene i kreditlinjen settes til *minus*
-- brutto- og nettobel�pene i avgiftslinjen.
-----------------------------------------------------------------------------
PROCEDURE OpprettKreditlinje ( r_krediteringslinje IN  AB_AVGIFTSLINJER%ROWTYPE )
IS
   v_brukernavn                  VARCHAR2(15);

BEGIN
   Zt.Trace ( 'AA0_TJ_02', 'OpprettKreditlinje: Start' );

   -- Hent brukernavn fra systemet
   SELECT   USER
   INTO     v_brukernavn
   FROM     DUAL;

   INSERT INTO AB_AVGIFTSLINJER
      ( AB_AVGIFTSLINJE_ID_N,
        AB_FAKTURASTED_ID,
        AB_FLYBEVEGELSE_ID,
        AB_AVGIFTSOMRAADE_ID,
        AB_IND_DEBET_KREDIT_VCH,
        AB_BELOEP_NETTO_N,
        AB_BELOEP_BRUTTO_N,
        AB_TIDSPUNKT_BEREGNET_D,
        AB_KREDITERT_C,
        AB_LUFTHAVN_KOSTNAD_ICAO_VCH,
        AB_FLYBEVEGELSE_ID_HAR,
        AB_REGISTRERINGSDATO_D_HAR,
        AB_MANUELL_OVERSTYRING_ID,
        AB_RABATT_N,
        AB_SPESIFIKASJONSNUMMER_VCH,
        AB_BEREGNINGSGRUNNLAG_PAX_N,
        AB_LINJETYPE_VCH,
        AB_TIDSPUNKT_OVERFOERT_FAKTURE,
        AB_BEREGNET_AV_VCH,
        AB_REF_SPESIFIKASJONSNR_VCH,
        AB_OVERSTYRINGSMERKNAD_VCH      )
   VALUES
      ( AVG_LINJ_SEQ.NEXTVAL,
        r_krediteringslinje.AB_FAKTURASTED_ID,
        r_krediteringslinje.AB_FLYBEVEGELSE_ID,
        r_krediteringslinje.AB_AVGIFTSOMRAADE_ID,
        K_AB.INDIKATOR_DEBETKREDIT_KREDIT,
        0 - r_krediteringslinje.AB_BELOEP_NETTO_N,  -- Negativt bel�p motsvarende opprinnelig nettobel�p
        0 - r_krediteringslinje.AB_BELOEP_BRUTTO_N, -- Negativt bel�p motsvarende opprinnelig bruttobel�p
        SYSDATE,
        K_AB.INDIKATOR_JANEI_NEI,
        r_krediteringslinje.AB_LUFTHAVN_KOSTNAD_ICAO_VCH,
        r_krediteringslinje.AB_FLYBEVEGELSE_ID_HAR,
        r_krediteringslinje.AB_REGISTRERINGSDATO_D_HAR,
        r_krediteringslinje.AB_MANUELL_OVERSTYRING_ID,
        r_krediteringslinje.AB_RABATT_N,
        NULL,
        r_krediteringslinje.AB_BEREGNINGSGRUNNLAG_PAX_N,
        r_krediteringslinje.AB_LINJETYPE_VCH,
        NULL,
        v_brukernavn,
        r_krediteringslinje.AB_SPESIFIKASJONSNUMMER_VCH,
        r_krediteringslinje.AB_OVERSTYRINGSMERKNAD_VCH      );

   -- Marker opprinnelig avgiftslinje som kreditert
   UPDATE   AB_AVGIFTSLINJER
   SET      AB_KREDITERT_C       = K_AB.INDIKATOR_JANEI_JA
   WHERE    AB_AVGIFTSLINJE_ID_N = r_krediteringslinje.AB_AVGIFTSLINJE_ID_N;

   Zt.Trace ( 'AA0_TJ_02', 'OpprettKreditlinje: Stopp' );

EXCEPTION
   WHEN OTHERS THEN
      Zt.Trace ( 'AA0_TJ_02', 'OpprettKreditlinje: Exception' );
      ZtErr.SetError ( 'AA0_TJ_02', E_AVG.ANNEN_FEIL, '[OpprettKreditlinje] ' || SQLERRM ||
                       '.  Kunne ikke opprette kreditlinje for avgiftslinje med ID ' || TO_CHAR ( r_krediteringslinje.AB_AVGIFTSLINJE_ID_N ) || '.' );
END OpprettKreditlinje;


-----------------------------------------------------------------------------
-- LagreAvgiftslinjegrunnlag
-----------------------------------------------------------------------------
-- Prosedyren kopierer hele flybevegelsen til AB_AVGIFTSLINJEGRUNNLAG.  For
-- hver avgiftslinje, gammel eller ny, foreligger flybevegelsen slik den s�
-- ut da avgiften ble beregnet, i AB_AVGIFTSLINJEGRUNNLAG.
-----------------------------------------------------------------------------
PROCEDURE LagreAvgiftslinjegrunnlag ( r_avgiftslinje IN OUT AB_AVGIFTSLINJER%ROWTYPE )
IS
   r_flybevegelse                AB_FLYBEVEGELSER%ROWTYPE;
   r_avgiftslinjegrunnlag        AB_AVGIFTSLINJEGRUNNLAG%ROWTYPE;
   b_opprett_avgiftslinjegrlag   BOOLEAN := FALSE;

BEGIN
   Zt.Trace ( 'AA0_TJ_02', 'LagreAvgiftslinjegrunnlag: Start' );

   -- Hent ut flybevegelsen som skal kopieres
   SELECT   *
   INTO     r_flybevegelse
   FROM     AB_FLYBEVEGELSER
   WHERE    AB_FLYBEVEGELSE_ID = r_avgiftslinje.AB_FLYBEVEGELSE_ID;

   -- Unders�k om avgiftslinjegrunnlaget allerede er lagret unna ifm. lagring av annen avgiftslinje
   BEGIN
      SELECT   *
      INTO     r_avgiftslinjegrunnlag
      FROM     AB_AVGIFTSLINJEGRUNNLAG
      WHERE    AB_FLYBEVEGELSE_ID     = r_avgiftslinje.AB_FLYBEVEGELSE_ID
         AND   AB_REGISTRERINGSDATO_D = r_flybevegelse.AB_ENDRET_DATO_D;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         -- Avgiftslinjegrunnlag finnes ikke, m� opprettes
         b_opprett_avgiftslinjegrlag := TRUE;
   END;

   IF ( b_opprett_avgiftslinjegrlag ) THEN
      -- Kopier flybevegelsen til AB_AVGIFTSLINJEGRUNNLAG
      INSERT INTO AB_AVGIFTSLINJEGRUNNLAG
         ( AB_FLYBEVEGELSE_ID,
           AB_KALLESIGNAL_VCH,
           AB_KATEGORI_C,
           AB_LUFTHAVN_DEP_ICAO_VCH,
           AB_LUFTHAVN_ARR_ICAO_VCH,
           AB_DATO_DEP_D,
           AB_DATO_ARR_D,
           AB_FAKTURASTED_DEP_VCH,
           AB_FAKTURASTED_ARR_VCH,
           AB_TOTALT_ANTALL_PASSASJERER_N,
           AB_TOTAL_OMBORD_N,
           AB_RSD_DATO_UTFOERT_D,
           AB_ADRNR_DEP_N,
           AB_ADRNR_ARR_N,
           AB_VFR_VCH,
           AB_FLYGNINGENS_ART_VCH,
           AB_RUNDFLYGNING_C,
           AB_FB_REF_ID_N,
           AB_MATCHET_MED_DTS_ID_N,
           AB_INNRAPPORTERT_AV_VCH,
           AB_REGMERKE_VCH,
           AB_MTOW_N,
           AB_ANTALL_SETER_N,
           AB_CREW_N,
           AB_PAX_BARN_N,
           AB_PAX_AVREIST_N,
           AB_PAX_TRANSFER_N,
           AB_PAX_TRANSITT_N,
           AB_PAX_ANKOMMET_N,
           AB_STOEYSERT_KODE_VCH,
           AB_MOTORGR_KODE_VCH,
           AB_FLYTYPE_VCH,
           AB_FLYTYPE_EC_VCH,
           AB_FARTOEYTYPE_KODE_VCH,
           AB_KUNDE_ID_DEP_N,
           AB_KUNDE_ID_ARR_N,
           AB_KUNDE_ICAO_VCH,
           AB_MIL_KODE_VCH,
           AB_KORT_PAA_TYPE_AVGIFT_VCH,
           AB_INNRAPPORTERT_CRCO_C,
           AB_FB_REF_MERKNAD_VCH,
           AB_OVERSTYRING_EC_C,
           AB_OVERSTYRINGSKODE_VCH,
           AB_REGISTRERINGSDATO_D          )
      VALUES
         ( r_flybevegelse.AB_FLYBEVEGELSE_ID,
           r_flybevegelse.AB_KALLESIGNAL_VCH,
           r_flybevegelse.AB_KATEGORI_C,
           r_flybevegelse.AB_LUFTHAVN_DEP_ICAO_VCH,
           r_flybevegelse.AB_LUFTHAVN_ARR_ICAO_VCH,
           r_flybevegelse.AB_DATO_DEP_D,
           r_flybevegelse.AB_DATO_ARR_D,
           r_flybevegelse.AB_FAKTURASTED_ID,
           r_flybevegelse.AB_FAKTURASTED_ID_ARR_FAKTURER,
           r_flybevegelse.AB_TOTALT_ANT_PASSASJERER_N,
           r_flybevegelse.AB_TOTAL_OMBORD_N,
           r_flybevegelse.AB_RSD_DATO_UTFOERT_D,
           r_flybevegelse.AB_ADRNR_DEP_N,
           r_flybevegelse.AB_ADRNR_ARR_N,
           r_flybevegelse.AB_VFR_VCH,
           r_flybevegelse.AB_FLYGNINGENS_ART_VCH,
           r_flybevegelse.AB_RUNDFLYGNING_C,
           r_flybevegelse.AB_FB_REF_ID_N,
           r_flybevegelse.AB_MATCHET_MED_DTS_ID_N,
           r_flybevegelse.AB_INNRAPPORTERT_AV_VCH,
           r_flybevegelse.AB_REGMERKE_VCH,
           r_flybevegelse.AB_MTOW_N,
           r_flybevegelse.AB_ANTALL_SETER_N,
           r_flybevegelse.AB_CREW_N,
           r_flybevegelse.AB_PAX_BARN_N,
           r_flybevegelse.AB_PAX_AVREIST_N,
           r_flybevegelse.AB_PAX_TRANSFER_N,
           r_flybevegelse.AB_PAX_TRANSITT_N,
           r_flybevegelse.AB_PAX_ANKOMMET_N,
           r_flybevegelse.AB_STOYSERT_KODE_VCH,
           r_flybevegelse.AB_MOTORGR_KODE_VCH,
           r_flybevegelse.AB_FLYTYPE_VCH,
           r_flybevegelse.AB_FLYTYPE_EC_VCH,
           r_flybevegelse.AB_FARTOEYTYPE_KODE_VCH,
           r_flybevegelse.AB_KUNDE_ID_DEP_N,
           r_flybevegelse.AB_KUNDE_ID_ARR_N,
           r_flybevegelse.AB_KUNDE_ICAO_VCH,
           r_flybevegelse.AB_MIL_KODE_VCH,
           r_flybevegelse.AB_KORT_PAA_TYPE_AVGIFT_VCH,
           r_flybevegelse.AB_INNRAPPORTERT_CRCO_C,
           r_flybevegelse.AB_FB_REF_MERKNAD_VCH,
           r_flybevegelse.AB_OVERSTYRING_EC_C,
           r_flybevegelse.AB_OVERSTYRINGSKODE_VCH,
           r_flybevegelse.AB_ENDRET_DATO_D                );
   END IF;

   -- Knytt avgiftslinjen til avgiftslinjegrunnlaget
   r_avgiftslinje.AB_FLYBEVEGELSE_ID_HAR     := r_flybevegelse.AB_FLYBEVEGELSE_ID;
   r_avgiftslinje.AB_REGISTRERINGSDATO_D_HAR := r_flybevegelse.AB_ENDRET_DATO_D;

   Zt.Trace ( 'AA0_TJ_02', 'LagreAvgiftslinjegrunnlag: Stopp' );

EXCEPTION
   WHEN OTHERS THEN
      Zt.Trace ( 'AA0_TJ_02', 'LagreAvgiftslinjegrunnlag: Exception' );
      ZtErr.SetError ( 'AA0_TJ_02', E_AVG.ANNEN_FEIL, '[LagreAvgiftslinjegrunnlag] ' || SQLERRM ||
                       '.  Flybevegelse-ID ' || TO_CHAR ( r_avgiftslinje.AB_FLYBEVEGELSE_ID ) );
END LagreAvgiftslinjegrunnlag;


-----------------------------------------------------------------------------
-- HentKostnadsdetaljer
-----------------------------------------------------------------------------
-- Prosedyren utleder fakturasted og kostnadslufthavn for avgiftslinjen.
-- Fakturasted er den fakturerende enhet som er ansvarlig for � fakturere
-- og kreve inn den beregnede avgiften, mens kostnadslufthavnen indikerer
-- hvilken region som skal f� overf�rt den innkrevde avgiften.
-----------------------------------------------------------------------------
PROCEDURE HentKostnadsdetaljer ( r_avgiftslinje IN OUT AB_AVGIFTSLINJER%ROWTYPE )
IS
   r_flybevegelse                AB_FLYBEVEGELSER%ROWTYPE;
   f_indikator_kostnadslufthavn  AB_AVGIFTSOMRAADER.AB_LUFTHAVN_KOSTNAD_VCH%TYPE;
   e_ukjent_kostnadssted         EXCEPTION;

BEGIN
   Zt.Trace ( 'AA0_TJ_02', 'HentKostnadsdetaljer: Start' );

   -- Hent flybevegelsesdata
   SELECT   *
   INTO     r_flybevegelse
   FROM     AB_FLYBEVEGELSER
   WHERE    AB_FLYBEVEGELSE_ID = r_avgiftslinje.AB_FLYBEVEGELSE_ID;

   -- Hent indikator for kostnadslufthavn fra avgiftsomr�det
   SELECT   AB_LUFTHAVN_KOSTNAD_VCH
   INTO     f_indikator_kostnadslufthavn
   FROM     AB_AVGIFTSOMRAADER
   WHERE    AB_AVGIFTSOMRAADE_ID = r_avgiftslinje.AB_AVGIFTSOMRAADE_ID;

   IF ( f_indikator_kostnadslufthavn IS NULL ) THEN
      IF ( ( r_avgiftslinje.AB_AVGIFTSOMRAADE_ID = K_AB.AVGOMRAADE_UNDERVEIS ) AND ( r_flybevegelse.AB_FLYGNINGENS_ART_VCH = K_AB.FLYGNINGSART_KONT_SOKKEL ) ) THEN
         -- Underveisavgift for kontinentalsokkelflygninger skal godskrives den landbaserte lufthavnen
         IF ( ( r_flybevegelse.AB_KONT_SOKKEL_DEP_C = K_AB.INDIKATOR_JANEI_JA ) AND ( r_flybevegelse.AB_KONT_SOKKEL_ARR_C = K_AB.INDIKATOR_JANEI_NEI ) ) THEN
            -- Ankomstlufthavnen (ARR) er landbasert
            r_avgiftslinje.AB_FAKTURASTED_ID            := r_flybevegelse.AB_FAKTURASTED_ID_ARR_FAKTURER;
            r_avgiftslinje.AB_LUFTHAVN_KOSTNAD_ICAO_VCH := r_flybevegelse.AB_LUFTHAVN_ARR_ICAO_VCH;
         ELSIF ( ( r_flybevegelse.AB_KONT_SOKKEL_DEP_C = K_AB.INDIKATOR_JANEI_NEI ) AND ( r_flybevegelse.AB_KONT_SOKKEL_ARR_C = K_AB.INDIKATOR_JANEI_JA ) ) THEN
            -- Avgangslufthavnen (DEP) er landbasert
            r_avgiftslinje.AB_FAKTURASTED_ID            := r_flybevegelse.AB_FAKTURASTED_ID;
            r_avgiftslinje.AB_LUFTHAVN_KOSTNAD_ICAO_VCH := r_flybevegelse.AB_LUFTHAVN_DEP_ICAO_VCH;
         ELSE
            -- Kostnaden godskrives Luftfartsverkets hovedadministrasjon
            r_avgiftslinje.AB_FAKTURASTED_ID            := K_AB.FAKTURASTED_LV;
            r_avgiftslinje.AB_LUFTHAVN_KOSTNAD_ICAO_VCH := NULL;
         END IF;
      ELSE
         -- Kostnad skal godskrives Luftfartsverkets hovedadministrasjon
         r_avgiftslinje.AB_FAKTURASTED_ID            := K_AB.FAKTURASTED_LV;
         r_avgiftslinje.AB_LUFTHAVN_KOSTNAD_ICAO_VCH := NULL;
      END IF;
   ELSIF ( f_indikator_kostnadslufthavn = K_AB.INDIKATOR_LUFTHAVN_DEP ) THEN
      -- Kostnader skal godskrives avgangslufthavnen
      r_avgiftslinje.AB_FAKTURASTED_ID            := r_flybevegelse.AB_FAKTURASTED_ID;
      r_avgiftslinje.AB_LUFTHAVN_KOSTNAD_ICAO_VCH := r_flybevegelse.AB_LUFTHAVN_DEP_ICAO_VCH;
   ELSIF ( f_indikator_kostnadslufthavn = K_AB.INDIKATOR_LUFTHAVN_ARR ) THEN
      -- Kostnader skal godskrives ankomstlufthavnen
      r_avgiftslinje.AB_FAKTURASTED_ID            := r_flybevegelse.AB_FAKTURASTED_ID_ARR_FAKTURER;
      r_avgiftslinje.AB_LUFTHAVN_KOSTNAD_ICAO_VCH := r_flybevegelse.AB_LUFTHAVN_ARR_ICAO_VCH;
   ELSE
      RAISE e_ukjent_kostnadssted;
   END IF;

   Zt.Trace ( 'AA0_TJ_02', 'HentKostnadsdetaljer: Stopp' );

EXCEPTION
   WHEN e_ukjent_kostnadssted THEN
      Zt.Trace ( 'AA0_TJ_02', 'HentKostnadsdetaljer: Exception' );
      ZtErr.SetError ( 'AA0_TJ_02', E_AVG.UKJENT_KOSTNADSSTED, '[HentKostnadsdetaljer] Avgiftsomr�de ' ||
                       r_avgiftslinje.AB_AVGIFTSOMRAADE_ID || '.' );
   WHEN NO_DATA_FOUND THEN
      Zt.Trace ( 'AA0_TJ_02', 'HentKostnadsdetaljer: Exception' );
      ZtErr.SetError ( 'AA0_TJ_02', E_AVG.FLYBEVEGELSEN_FINNES_IKKE, '[HentKostnadsdetaljer] Flybevegelses-ID ' ||
                       TO_CHAR ( r_avgiftslinje.AB_FLYBEVEGELSE_ID ) || '.' );
   WHEN OTHERS THEN
      Zt.Trace ( 'AA0_TJ_02', 'HentKostnadsdetaljer: Exception' );
      ZtErr.SetError ( 'AA0_TJ_02', E_AVG.ANNEN_FEIL, '[HentKostnadsdetaljer] ' || SQLERRM || '.  Flybevegelses-ID ' ||
                       TO_CHAR ( r_avgiftslinje.AB_FLYBEVEGELSE_ID ) || '.' );
END HentKostnadsdetaljer;


-----------------------------------------------------------------------------
-- LagreAvgiftslinje
-----------------------------------------------------------------------------
-- Prosedyren lagrer den ferdige avgiftslinjen p� databasen.  Om en
-- ikke-fakturert avgiftslinje allerede eksisterer for avgiften, overskrives
-- denne, ellers opprettes det en ny avgiftslinje.
-----------------------------------------------------------------------------
PROCEDURE LagreAvgiftslinje ( r_avgiftslinje           IN OUT  AB_AVGIFTSLINJER%ROWTYPE,
                              b_overskriv_eksisterende IN      BOOLEAN                   )
IS
   v_brukernavn                  VARCHAR2(15);

BEGIN
   Zt.Trace ( 'AA0_TJ_02', 'LagreAvgiftslinje: Start' );

   -- Hent brukernavn fra systemet
   SELECT   USER
   INTO     v_brukernavn
   FROM     DUAL;

   IF ( b_overskriv_eksisterende ) THEN
      -- Slett delavgiftslinjer knyttet til avgiftslinjen som overskrives
      DELETE
      FROM     AB_DELAVGIFTER
      WHERE    AB_AVGIFTSLINJE_ID_N = r_avgiftslinje.AB_AVGIFTSLINJE_ID_N;

      -- Overskriv eksisterende avgiftslinje
      UPDATE   AB_AVGIFTSLINJER
      SET      AB_FLYBEVEGELSE_ID             = r_avgiftslinje.AB_FLYBEVEGELSE_ID,
               AB_AVGIFTSOMRAADE_ID           = r_avgiftslinje.AB_AVGIFTSOMRAADE_ID,
               AB_IND_DEBET_KREDIT_VCH        = K_AB.INDIKATOR_DEBETKREDIT_DEBET,
               AB_BELOEP_NETTO_N              = r_avgiftslinje.AB_BELOEP_NETTO_N,
               AB_BELOEP_BRUTTO_N             = r_avgiftslinje.AB_BELOEP_BRUTTO_N,
               AB_TIDSPUNKT_BEREGNET_D        = SYSDATE,
               AB_LUFTHAVN_KOSTNAD_ICAO_VCH   = r_avgiftslinje.AB_LUFTHAVN_KOSTNAD_ICAO_VCH,
               AB_FLYBEVEGELSE_ID_HAR         = r_avgiftslinje.AB_FLYBEVEGELSE_ID_HAR,
               AB_REGISTRERINGSDATO_D_HAR     = r_avgiftslinje.AB_REGISTRERINGSDATO_D_HAR,
               AB_KREDITERT_C                 = K_AB.INDIKATOR_JANEI_NEI,
               AB_MANUELL_OVERSTYRING_ID      = NULL,
               AB_RABATT_N                    = 100 - ( r_avgiftslinje.AB_BELOEP_NETTO_N / r_avgiftslinje.AB_BELOEP_BRUTTO_N ) * 100,
               AB_SPESIFIKASJONSNUMMER_VCH    = NULL,
               AB_BEREGNINGSGRUNNLAG_PAX_N    = r_avgiftslinje.AB_BEREGNINGSGRUNNLAG_PAX_N,
               AB_LINJETYPE_VCH               = r_avgiftslinje.AB_LINJETYPE_VCH,
               AB_TIDSPUNKT_OVERFOERT_FAKTURE = NULL,
               AB_BEREGNET_AV_VCH             = v_brukernavn,
               AB_REF_SPESIFIKASJONSNR_VCH    = NULL,
               AB_OVERSTYRINGSMERKNAD_VCH     = NULL
        WHERE  AB_AVGIFTSLINJE_ID_N           = r_avgiftslinje.AB_AVGIFTSLINJE_ID_N;
   ELSE
      -- Opprett ny avgiftslinje
      INSERT INTO AB_AVGIFTSLINJER
         ( AB_AVGIFTSLINJE_ID_N,
           AB_FAKTURASTED_ID,
           AB_FLYBEVEGELSE_ID,
           AB_AVGIFTSOMRAADE_ID,
           AB_IND_DEBET_KREDIT_VCH,
           AB_BELOEP_NETTO_N,
           AB_BELOEP_BRUTTO_N,
           AB_TIDSPUNKT_BEREGNET_D,
           AB_KREDITERT_C,
           AB_LUFTHAVN_KOSTNAD_ICAO_VCH,
           AB_FLYBEVEGELSE_ID_HAR,
           AB_REGISTRERINGSDATO_D_HAR,
           AB_MANUELL_OVERSTYRING_ID,
           AB_RABATT_N,
           AB_SPESIFIKASJONSNUMMER_VCH,
           AB_BEREGNINGSGRUNNLAG_PAX_N,
           AB_LINJETYPE_VCH,
           AB_TIDSPUNKT_OVERFOERT_FAKTURE,
           AB_BEREGNET_AV_VCH,
           AB_REF_SPESIFIKASJONSNR_VCH,
           AB_OVERSTYRINGSMERKNAD_VCH      )
      VALUES
         ( AVG_LINJ_SEQ.NEXTVAL,
           r_avgiftslinje.AB_FAKTURASTED_ID,
           r_avgiftslinje.AB_FLYBEVEGELSE_ID,
           r_avgiftslinje.AB_AVGIFTSOMRAADE_ID,
           K_AB.INDIKATOR_DEBETKREDIT_DEBET,
           r_avgiftslinje.AB_BELOEP_NETTO_N,
           r_avgiftslinje.AB_BELOEP_BRUTTO_N,
           SYSDATE,
           K_AB.INDIKATOR_JANEI_NEI,
           r_avgiftslinje.AB_LUFTHAVN_KOSTNAD_ICAO_VCH,
           r_avgiftslinje.AB_FLYBEVEGELSE_ID_HAR,
           r_avgiftslinje.AB_REGISTRERINGSDATO_D_HAR,
           NULL,
           100 - ( r_avgiftslinje.AB_BELOEP_NETTO_N / r_avgiftslinje.AB_BELOEP_BRUTTO_N ) * 100,
           NULL,
           r_avgiftslinje.AB_BEREGNINGSGRUNNLAG_PAX_N,
           r_avgiftslinje.AB_LINJETYPE_VCH,
           NULL,
           v_brukernavn,
           NULL,
           NULL  );

      -- Hent ut IDen til avgiftslinjen som akkurat ble opprettet
      SELECT   AVG_LINJ_SEQ.CURRVAL
      INTO     r_avgiftslinje.AB_AVGIFTSLINJE_ID_N
      FROM     DUAL;
   END IF;

   Zt.Trace ( 'AA0_TJ_02', 'LagreAvgiftslinje: Stopp' );

EXCEPTION
   WHEN NO_DATA_FOUND THEN
      Zt.Trace ( 'AA0_TJ_02', 'LagreAvgiftslinje: Exception' );
      ZtErr.SetError ( 'AA0_TJ_02', E_AVG.AVGIFTSLINJE_FINNES_IKKE, '[LagreAvgiftslinje] Avgiftslinje-ID ' || TO_CHAR ( r_avgiftslinje.AB_AVGIFTSLINJE_ID_N ) || '.' );
   WHEN OTHERS THEN
      Zt.Trace ( 'AA0_TJ_02', 'LagreAvgiftslinje: Exception' );
      ZtErr.SetError ( 'AA0_TJ_02', E_AVG.ANNEN_FEIL, '[LagreAvgiftslinje] ' || SQLERRM || '.  Kunne ikke legge inn avgiftslinjen.' );
END LagreAvgiftslinje;


-----------------------------------------------------------------------------
-- TilknyttDelavgiftslinjer
-----------------------------------------------------------------------------
-- Prosedyren knytter delavgiftslinjene som ligger til grunn for en
-- avgiftslinje, opp mot avgiftslinjen.  P� den m�ten sikres sporbarheten,
-- gjennom at enhver avgiftslinje har knyttet til seg delavgiftslinjer, som
-- i sin tur peker tilbake p� regelen/avtalen (inkl. paragrafnummer) som
-- ligger til grunn for delavgiftenm, og dermed for totalavgiften.
-----------------------------------------------------------------------------
PROCEDURE TilknyttDelavgiftslinjer ( r_avgiftslinje IN  AB_AVGIFTSLINJER%ROWTYPE )
IS
   f_avgiftslinje_id             AB_AVGIFTSLINJER.AB_AVGIFTSLINJE_ID_N%TYPE;

   CURSOR m_delavgifter IS
      SELECT   *
      FROM     AB_DELAVGIFTER
      WHERE    AB_FLYBEVEGELSE_ID   = r_avgiftslinje.AB_FLYBEVEGELSE_ID
         AND   AB_AVGIFTSOMRAADE_ID = r_avgiftslinje.AB_AVGIFTSOMRAADE_ID
         AND   AB_BEHANDLET_C       = K_AB.INDIKATOR_JANEI_NEI
      ORDER BY AB_DELAVGIFT_ID;

BEGIN
   Zt.Trace ( 'AA0_TJ_02', 'TilknyttDelavgiftslinjer: Start' );

   FOR r_delavgift IN m_delavgifter LOOP
      -- Opprett knytning til AB_AVGIFTSLINJER for delavgiftslinjene som inng�r i totalavgiften
      UPDATE   AB_DELAVGIFTER
      SET      AB_AVGIFTSLINJE_ID_N = r_avgiftslinje.AB_AVGIFTSLINJE_ID_N,
               AB_BEHANDLET_C       = K_AB.INDIKATOR_JANEI_JA
      WHERE    AB_DELAVGIFT_ID      = r_delavgift.AB_DELAVGIFT_ID;
   END LOOP;

   Zt.Trace ( 'AA0_TJ_02', 'TilknyttDelavgiftslinjer: Stopp' );

EXCEPTION
   WHEN OTHERS THEN
      Zt.Trace ( 'AA0_TJ_02', 'TilknyttDelavgiftslinjer: Exception' );
      ZtErr.SetError ( 'AA0_TJ_02', E_AVG.ANNEN_FEIL, '[LagreAvgiftslinje] ' || SQLERRM || '.  Flybevegelses-ID ' || TO_CHAR ( r_avgiftslinje.AB_FLYBEVEGELSE_ID ) ||
                       ', avgiftsomr�de ' || r_avgiftslinje.AB_AVGIFTSOMRAADE_ID || '.' );
END TilknyttDelavgiftslinjer;


-----------------------------------------------------------------------------
-- OpprettAvgiftslinje
-----------------------------------------------------------------------------
-- Prosedyren formaterer avgiftslinjen for lagring.  Om det allerede finnes
-- en fakturert, ikke-kreditert avgiftslinje p� avgiften, opprettes f�rst en
-- kreditlinje slik at kunden mottar en kreditnota p� det innbetalte bel�pet
-- f�r han mottar en faktura p� det nye bel�pet.  Om det ikke finnes en
-- fakturert avgiftslinje p� avgiften, unders�kes det hvorvidt det finnes en
-- ikke-fakturert avgiftslinje som kan overskrives, eller om avgiftslinjen
-- m� opprettes fra bunnen av.
-----------------------------------------------------------------------------
PROCEDURE OpprettAvgiftslinje ( r_avgiftslinje IN OUT AB_AVGIFTSLINJER%ROWTYPE )
IS
   r_gammel_avgiftslinje         AB_AVGIFTSLINJER%ROWTYPE;
   b_avgiftslinje_finnes         BOOLEAN := TRUE;
   b_overskriv_eksisterende      BOOLEAN := FALSE;
   b_kreditlinje_opprettet       BOOLEAN := FALSE;
   e_kreditlinje_ikke_opprettet  EXCEPTION;

BEGIN
   Zt.Trace ( 'AA0_TJ_02', 'OpprettAvgiftslinje: Start' );

   -- Utled fakturasted og kostnadslufthavn for avgiften
   HentKostnadsdetaljer ( r_avgiftslinje );

   BEGIN
      -- Hent evt. eksisterende, fakturert, ikke-kreditert avgiftslinje for samme avgift
      SELECT   *
      INTO     r_gammel_avgiftslinje
      FROM     AB_AVGIFTSLINJER
      WHERE    AB_AVGIFTSOMRAADE_ID           =  r_avgiftslinje.AB_AVGIFTSOMRAADE_ID
         AND   AB_FLYBEVEGELSE_ID             =  r_avgiftslinje.AB_FLYBEVEGELSE_ID
         AND   AB_LINJETYPE_VCH               =  K_AB.LINJETYPE_AUTOMATISK
         AND   AB_IND_DEBET_KREDIT_VCH        =  K_AB.INDIKATOR_DEBETKREDIT_DEBET
         AND   AB_KREDITERT_C                 =  K_AB.INDIKATOR_JANEI_NEI
         AND   AB_TIDSPUNKT_OVERFOERT_FAKTURE IS NOT NULL;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         -- Ingen fakturert, ikke-kreditert avgiftslinje eksisterer for avgiften
         b_avgiftslinje_finnes := FALSE;
   END;

   IF ( b_avgiftslinje_finnes ) THEN
      IF ( KreditlinjeSkalOpprettes ( r_avgiftslinje, r_gammel_avgiftslinje ) ) THEN
         -- Bel�p og/eller kundekopling er endret for avgiften; opprett kreditlinje
         OpprettKreditlinje ( r_gammel_avgiftslinje );

         -- Sett flagg som indikerer at kreditlinje er opprettet
         b_kreditlinje_opprettet := TRUE;
      END IF;
   ELSE
      BEGIN
         -- Unders�k om det finnes en ikke-fakturert avgiftslinje for avgiften
         SELECT   *
         INTO     r_gammel_avgiftslinje
         FROM     AB_AVGIFTSLINJER
         WHERE    AB_AVGIFTSOMRAADE_ID           =  r_avgiftslinje.AB_AVGIFTSOMRAADE_ID
            AND   AB_FLYBEVEGELSE_ID             =  r_avgiftslinje.AB_FLYBEVEGELSE_ID
            AND   AB_IND_DEBET_KREDIT_VCH        =  K_AB.INDIKATOR_DEBETKREDIT_DEBET
            AND   AB_LINJETYPE_VCH               =  K_AB.LINJETYPE_AUTOMATISK
            AND   AB_TIDSPUNKT_OVERFOERT_FAKTURE IS NULL;

         -- Setter flagg som indikerer at eksisterende avgiftslinje skal overskrives
         b_overskriv_eksisterende := TRUE;

         -- Tar vare p� IDen til avgiftslinjen som skal overskrives
         r_avgiftslinje.AB_AVGIFTSLINJE_ID_N := r_gammel_avgiftslinje.AB_AVGIFTSLINJE_ID_N;

      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            NULL;
      END;
   END IF;

   IF ( ( b_avgiftslinje_finnes ) AND ( NOT b_kreditlinje_opprettet ) ) THEN
      RAISE e_kreditlinje_ikke_opprettet;
   ELSIF ( r_avgiftslinje.AB_BELOEP_NETTO_N > 0 ) THEN
      -- Kopier flybevegelsen til AB_AVGIFTSLINJEGRUNNLAG
      LagreAvgiftslinjegrunnlag ( r_avgiftslinje );

      -- Lagre avgiftslinjen
      LagreAvgiftslinje ( r_avgiftslinje, b_overskriv_eksisterende );

      -- Opprett knytning mellom avgiftslinjen og underliggende delavgifter
      TilknyttDelavgiftslinjer ( r_avgiftslinje );
   ELSE
      -- Ingen ny avgiftslinje opprettet; slett underliggende delavgiftslinjer
      DELETE
      FROM     AB_DELAVGIFTER
      WHERE    AB_FLYBEVEGELSE_ID   = r_avgiftslinje.AB_FLYBEVEGELSE_ID
         AND   AB_AVGIFTSOMRAADE_ID = r_avgiftslinje.AB_AVGIFTSOMRAADE_ID
         AND   AB_BEHANDLET_C       = K_AB.INDIKATOR_JANEI_NEI;
   END IF;

   Zt.Trace ( 'AA0_TJ_02', 'OpprettAvgiftslinje: Stopp' );

EXCEPTION
   WHEN e_kreditlinje_ikke_opprettet THEN
      Zt.Trace ( 'AA0_TJ_02', 'OpprettAvgiftslinje: Exception' );
      ZtErr.SetError ( 'AA0_TJ_02', E_AVG.KREDITLINJE_IKKE_OPPRETTET, '[OpprettAvgiftslinje] Flybevegelses-ID ' ||
                       TO_CHAR ( r_avgiftslinje.AB_FLYBEVEGELSE_ID ) || ', avgiftsomr�de ' || r_avgiftslinje.AB_AVGIFTSOMRAADE_ID || '.' );
   WHEN OTHERS THEN
      Zt.Trace ( 'AA0_TJ_02', 'OpprettAvgiftslinje: Exception' );
      ZtErr.SetError ( 'AA0_TJ_02', E_AVG.FEIL_VED_OPPRETT_AVGIFTSLINJE, '[OpprettAvgiftslinje] ' || SQLERRM || '.  Flybevegelses-ID ' ||
                       TO_CHAR ( r_avgiftslinje.AB_FLYBEVEGELSE_ID ) || ', avgiftsomr�de ' || r_avgiftslinje.AB_AVGIFTSOMRAADE_ID || '.' );
END OpprettAvgiftslinje;


-----------------------------------------------------------------------------
-- VurderDelvisFritak
-----------------------------------------------------------------------------
-- Prosedyren vurderer hvorvidt en flybevegelse som potensielt kan faktureres
-- av to ulike fakturasteder (OAer), i praksis bare faktureres av ett av
-- dem. I s� fall settes fritakskoden for flybevegelsen til "Delvis fritatt".
-----------------------------------------------------------------------------
PROCEDURE VurderDelvisFritak ( f_flybevegelse_id IN  AB_FLYBEVEGELSER.AB_FLYBEVEGELSE_ID%TYPE )
IS
   r_dummy_avgiftslinje          AB_AVGIFTSLINJER%ROWTYPE;
   f_fakturasted_dep             AB_FLYBEVEGELSER.AB_FAKTURASTED_ID%TYPE;
   f_fakturasted_arr             AB_FLYBEVEGELSER.AB_FAKTURASTED_ID_ARR_FAKTURER%TYPE;
   b_dep_fakturerer              BOOLEAN := TRUE;
   b_arr_fakturerer              BOOLEAN := TRUE;

BEGIN
   Zt.Trace ( 'AA0_TJ_02', 'VurderDelvisFritak: Start' );

   -- Hent DEP- og ARR-fakturastedene for flybevegelsen
   SELECT   AB_FAKTURASTED_ID,
            AB_FAKTURASTED_ID_ARR_FAKTURER
   INTO     f_fakturasted_dep,
            f_fakturasted_arr
   FROM     AB_FLYBEVEGELSER
   WHERE    AB_FLYBEVEGELSE_ID = f_flybevegelse_id;

   IF ( f_fakturasted_dep != f_fakturasted_arr ) THEN
      BEGIN
         -- Unders�k om DEP-fakturasted har noen avgifter � fakturere
         SELECT   *
         INTO     r_dummy_avgiftslinje
         FROM     AB_AVGIFTSLINJER
         WHERE    AB_FLYBEVEGELSE_ID             =  f_flybevegelse_id
            AND   AB_FAKTURASTED_ID              =  f_fakturasted_dep
            AND   AB_LINJETYPE_VCH               =  K_AB.LINJETYPE_AUTOMATISK
            AND   AB_IND_DEBET_KREDIT_VCH        =  K_AB.INDIKATOR_DEBETKREDIT_DEBET
            AND   AB_TIDSPUNKT_OVERFOERT_FAKTURE IS NULL;

      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            -- Ingen rader funnet betyr at DEP-fakturastedet ikke fakturerer
            b_dep_fakturerer := FALSE;
         WHEN TOO_MANY_ROWS THEN
            NULL;
      END;

      BEGIN
         -- Unders�k om ARR-fakturasted har noen avgifter � fakturere
         SELECT   *
         INTO     r_dummy_avgiftslinje
         FROM     AB_AVGIFTSLINJER
         WHERE    AB_FLYBEVEGELSE_ID             =  f_flybevegelse_id
            AND   AB_FAKTURASTED_ID              =  f_fakturasted_arr
            AND   AB_LINJETYPE_VCH               =  K_AB.LINJETYPE_AUTOMATISK
            AND   AB_IND_DEBET_KREDIT_VCH        =  K_AB.INDIKATOR_DEBETKREDIT_DEBET
            AND   AB_TIDSPUNKT_OVERFOERT_FAKTURE IS NULL;

      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            -- Ingen rader funnet betyr at ARR-fakturastedet ikke fakturerer
            b_arr_fakturerer := FALSE;
         WHEN TOO_MANY_ROWS THEN
            NULL;
      END;

      IF ( b_dep_fakturerer != b_arr_fakturerer ) THEN
         -- Sett fritakskoden for flybevegelsen til "Delvis fritatt"
         UPDATE   AB_FLYBEVEGELSER
         SET      AB_FRITAKSKODE_ID  = K_AB.FRITAKSKODE_DELVIS_FRITATT
         WHERE    AB_FLYBEVEGELSE_ID = f_flybevegelse_id;
      END IF;

   END IF;

   Zt.Trace ( 'AA0_TJ_02', 'VurderDelvisFritak: Stopp' );

EXCEPTION
   WHEN OTHERS THEN
      Zt.Trace ( 'AA0_TJ_02', 'VurderDelvisFritak: Exception' );
      ZtErr.SetError ( 'AA0_TJ_02', E_AVG.ANNEN_FEIL, SQLERRM || '.  [VurderDelvisFritak] Flybevegelses-ID ' || TO_CHAR ( f_flybevegelse_id ) || '.' );
END VurderDelvisFritak;


-----------------------------------------------------------------------------
-- AA0_TJ_02
-----------------------------------------------------------------------------
-- Hovedl�kke.  Her gjennoml�pes de eksisterende avgiftsomr�dene, og for
-- hvert avgiftsomr�de summeres delavgiftene sammen til �n enkeltavgift for
-- omr�det.  Til slutt opprettes en avgiftslinje for omr�det.
-----------------------------------------------------------------------------
BEGIN

   Zt.Trace ( 'AA0_TJ_02', 'AA0_TJ_02: Start' );

   IF ( NOT GenereltFritatt ( f_flybevegelse_id ) ) THEN
      -- Initialiserer kjente verdier i avgiftslinje-forekomsten
      r_avgiftslinje.AB_FLYBEVEGELSE_ID   := f_flybevegelse_id;
      r_avgiftslinje.AB_LINJETYPE_VCH     := K_AB.LINJETYPE_AUTOMATISK;
      FOR r_avgiftsomraade IN m_avgiftsomraader LOOP
         -- Knytt avgiftslinjen til avgiftsomr�det
         r_avgiftslinje.AB_AVGIFTSOMRAADE_ID := r_avgiftsomraade.AB_AVGIFTSOMRAADE_ID;

         -- Bruttoavgift initialiseres til 0 og brutto- og nettoavgift beregnes ut fra beregnede delavgifter
         r_avgiftslinje.AB_BELOEP_BRUTTO_N := 0;
         r_avgiftslinje.AB_BELOEP_NETTO_N  := SummerDelavgifter ( K_AB.ID_REGEL_NULLREGEL, 0, r_avgiftslinje, r_avgiftslinje.AB_BELOEP_BRUTTO_N );

         -- Vurder om avgiftslinjen skal lagres p� databasen
         OpprettAvgiftslinje ( r_avgiftslinje );

         -- Sett flagg som indikerer om det ble beregnet avgift for dette avgiftsomr�det
         b_avgift_beregnet := ( b_avgift_beregnet OR ( r_avgiftslinje.AB_BELOEP_NETTO_N > 0 ) );
      END LOOP;

      IF ( NOT b_avgift_beregnet ) THEN
         -- Ingen avgift beregnet, sett fritakskode til "Avgiftsberegnet til 0"
         UPDATE   AB_FLYBEVEGELSER
         SET      AB_FRITAKSKODE_ID  = K_AB.FRITAKSKODE_AVG_BER_NULL
         WHERE    AB_FLYBEVEGELSE_ID = f_flybevegelse_id;
      ELSE
         -- Avgift beregnet, vurder om flybevegelsen er "Delvis fritatt"...
         VurderDelvisFritak ( f_flybevegelse_id );
      END IF;

   END IF;

   Zt.Trace ( 'AA0_TJ_02', 'AA0_TJ_02: Stopp' );

EXCEPTION
   WHEN OTHERS THEN
      Zt.Trace ( 'AA0_TJ_02', 'AA0_TJ_02: Exception' );
      ZtErr.SetError ( 'AA0_TJ_02', E_AVG.ANNEN_FEIL, '[Hovedl�kke] ' || SQLERRM || '.  Flybevegelse-ID ' || TO_CHAR ( f_flybevegelse_id ) || '.' );
END AA0_TJ_02;


/*-----------------------------------------------------------------------------
 Tjeneste
    AA0_TJ_03
-------------------------------------------------------------------------------
 Beskrivelse
    Tjenesten matcher angitt regel mot angitt flybevegelse og returnerer TRUE
    dersom regelen matcher, FALSE ellers.
 Parametere
    Regel-ID
    Flybevegelses-ID
    Flagg som indikerer hvorvidt delavgift skal beregnes eller ikke ved match
 Returverdier
    TRUE:  Regelen matcher for angitt flybevegelse
    FALSE: Regelen matcher ikke for angitt flybevegelse
 Logg
    04-MAR-1999  Anders Blehr       - P�begynt som MatchRegel i AA0_TJ_01
    23-MAR-1999  Anders Blehr       - Hovedsakelig ferdigprogrammert
    04-MAI-1999  Anders Blehr       - Ferdigprogrammert som MatchRegel
    05-MAI-1999  Anders Blehr       - Skilt ut som egen tjeneste AA0_TJ_03
-----------------------------------------------------------------------------*/
FUNCTION AA0_TJ_03 ( f_denne_regel      IN  AB_REGLER.AB_REGEL_ID%TYPE,
                     f_flybevegelse_id  IN  AB_FLYBEVEGELSER.AB_FLYBEVEGELSE_ID%TYPE,
                     b_beregn_delavgift IN  BOOLEAN                                   )
RETURN
   BOOLEAN
IS
   b_match                       BOOLEAN := TRUE;
   r_regeldetaljer               AB_REGEL_DETALJER%ROWTYPE;
   r_siste_gyldighetsomraade     AB_GYLDIGHETSOMR%ROWTYPE;

   CURSOR m_gyldighetsomraader IS
      SELECT   *
      FROM     AB_GYLDIGHETSOMR
      WHERE    AB_REGEL_DETALJ_ID       = r_regeldetaljer.AB_REGEL_DETALJ_ID
         AND   AB_BEREGNINGSINDIKATOR_C = K_AB.INDIKATOR_JANEI_NEI
      ORDER BY AB_GYLDIGHETSOMR_ID;


-----------------------------------------------------------------------------
-- HentRegeldetaljer
-----------------------------------------------------------------------------
-- Funksjonen henter den regeldetalj-forekomsten knyttet til innkommende
-- regel, som er gyldig for flygningsdatoen.  Returverdien er TRUE om en slik
-- forekomst finnes; FALSE ellers.
-----------------------------------------------------------------------------
FUNCTION HentRegeldetaljer ( f_regel_id        IN  AB_REGLER.AB_REGEL_ID%TYPE,
                             f_flybevegelse_id IN  AB_FLYBEVEGELSER.AB_FLYBEVEGELSE_ID%TYPE,
                             r_regeldetaljer   OUT AB_REGEL_DETALJER%ROWTYPE                 )
RETURN
   BOOLEAN
IS
   f_flygningsdatoindikator      AB_AVGIFTSOMRAADER.AB_LUFTHAVN_KOSTNAD_VCH%TYPE;
   f_dato_dep                    AB_FLYBEVEGELSER.AB_DATO_DEP_D%TYPE;
   f_dato_arr                    AB_FLYBEVEGELSER.AB_DATO_ARR_D%TYPE;
   f_flygningsdato               AB_FLYBEVEGELSER.AB_DATO_DEP_D%TYPE;
   b_regeldetaljer_finnes        BOOLEAN := TRUE;

BEGIN
   Zt.Trace ( 'AA0_TJ_03', 'HentRegeldetaljer: Start' );

   -- Hent avgangs- og ankomstdatoene for flybevegelsen
   SELECT   NVL ( AB_DATO_DEP_D, AB_RSD_DATO_UTFOERT_D ),
            NVL ( AB_DATO_ARR_D, AB_RSD_DATO_UTFOERT_D )
   INTO     f_dato_dep,
            f_dato_arr
   FROM     AB_FLYBEVEGELSER
   WHERE    AB_FLYBEVEGELSE_ID = f_flybevegelse_id;

   -- Hent flygningsdatoindikator for avgiftsomr�det (kostnadslufthavn for avgiftsomr�det angir hvilken av ankomst- og
   -- avgangsdatoene for flybevegelsen som skal regnes som flygningsdato).
   SELECT   b.AB_LUFTHAVN_KOSTNAD_VCH
   INTO     f_flygningsdatoindikator
   FROM     AB_REGLER a,
            AB_AVGIFTSOMRAADER b
   WHERE    a.AB_REGEL_ID          = f_regel_id
      AND   b.AB_AVGIFTSOMRAADE_ID = a.AB_AVGIFTSOMRAADE_ID;

   -- Avgj�r hvilken dato som skal regnes som flygningsdato
   IF ( f_flygningsdatoindikator IN ( K_AB.INDIKATOR_LUFTHAVN_DEP, K_AB.INDIKATOR_LUFTHAVN_INGEN ) ) THEN
      f_flygningsdato := f_dato_dep;
   ELSE
      f_flygningsdato := f_dato_arr;
   END IF;

   -- Hent regeldetaljer som gjelder for flygningsdatoen
   BEGIN
      SELECT   *
      INTO     r_regeldetaljer
      FROM     AB_REGEL_DETALJER
      WHERE    AB_REGEL_ID                               = f_regel_id
         AND   AB_VERIFISERT_C                           = K_AB.INDIKATOR_JANEI_JA
         AND   AB_SLETTET_C                              = K_AB.INDIKATOR_JANEI_NEI
         AND         AB_GYLDIG_FRA_D                    <= f_flygningsdato
         AND   NVL ( AB_GYLDIG_TIL_D, f_flygningsdato ) >= f_flygningsdato;

   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         b_regeldetaljer_finnes := false;
   END;

   Zt.Trace ( 'AA0_TJ_03', 'HentRegeldetaljer: Stopp' );

   RETURN b_regeldetaljer_finnes;

EXCEPTION
   WHEN OTHERS THEN
      Zt.Trace ( 'AA0_TJ_03', 'HentRegeldetaljer: Exception' );
      ZtErr.SetError ( 'AA0_TJ_03', E_AVG.ANNEN_FEIL, '[HentRegeldetaljer] ' || SQLERRM || '.  Flybevegelses-ID ' || TO_CHAR ( f_flybevegelse_id ) ||
                       ', regel-ID ' || TO_CHAR ( f_regel_id ) || '.' );
END HentRegeldetaljer;


-----------------------------------------------------------------------------
-- HentSammenlikningsverdi
-----------------------------------------------------------------------------
-- Funksjonen henter ut og returnerer data - sammenlikningsverdien - fra
-- angitt kolonne i flybevegelsestabellen.  Uthentingen skjer vha. dynamisk
-- SQL, og verdien konverteres til VARCHAR2 f�r den returneres.
-----------------------------------------------------------------------------
FUNCTION HentSammenlikningsverdi ( f_flybevegelse_id    IN  AB_FLYBEVEGELSER.AB_FLYBEVEGELSE_ID%TYPE,
                                   r_gyldighetskategori IN  AB_KATEGORIER_GYLDIGHETSOMR%ROWTYPE,
                                   f_typeangivelse      IN  VARCHAR2                                  )
RETURN
   AB_VERDIER_GYLDIGHETSOMR.AB_VERDI_VCH%TYPE
IS
   v_sql                         VARCHAR2(256);
   n_cursor                      INTEGER;
   n_ignorer                     INTEGER;
   f_sammenlikningsverdi         AB_VERDIER_GYLDIGHETSOMR.AB_VERDI_VCH%TYPE;
   n_sammenlikningsverdi         NUMBER(20);
   d_sammenlikningsverdi         DATE;

BEGIN
   Zt.Trace ( 'AA0_TJ_03', 'HentSammenlikningsverdi: Start' );

   -- Opprett cursor som skal benyttes ifm. dynamisk uthenting av sammenlikningsverdi
   n_cursor := DBMS_SQL.OPEN_CURSOR;

   -- Sett sammen SQL-setningen som henter sammenlikningsverdien fra databasen
   v_sql := 'SELECT ' || r_gyldighetskategori.AB_REF_KOLONNE_VCH ||
            ' INTO   :v_1' ||
            ' FROM   AB_FLYBEVEGELSER' ||
            ' WHERE  AB_FLYBEVEGELSE_ID = ' || TO_CHAR ( f_flybevegelse_id );

   -- Kompiler SQL-setningen
   DBMS_SQL.PARSE ( n_cursor, v_sql, DBMS_SQL.NATIVE );

   -- Knytt kolonnen i SELECT-setningen til riktig lokal variabel
   IF ( f_typeangivelse IN ( K_AB.ANGIVELSE_TYPE_VARCHAR, K_AB.ANGIVELSE_TYPE_CHAR ) ) THEN
      DBMS_SQL.DEFINE_COLUMN ( n_cursor, 1, f_sammenlikningsverdi, K_AB.LENGDE_SAMMENLIKNINGSVERDI_VCH );
   ELSIF ( f_typeangivelse = K_AB.ANGIVELSE_TYPE_NUMBER ) THEN
      DBMS_SQL.DEFINE_COLUMN ( n_cursor, 1, n_sammenlikningsverdi );
   ELSIF ( f_typeangivelse = K_AB.ANGIVELSE_TYPE_DATE ) THEN
      DBMS_SQL.DEFINE_COLUMN ( n_cursor, 1, d_sammenlikningsverdi );
   END IF;

   -- Utf�r SQL-setningen (returverdien kan ignoreres for SELECT-setninger)
   n_ignorer := DBMS_SQL.EXECUTE_AND_FETCH ( n_cursor );

   -- Hent ut sammenlikningsverdien fra cursoren og konverter den til VARCHAR2 om kolonnen har en annen datatype
   IF ( f_typeangivelse IN ( K_AB.ANGIVELSE_TYPE_VARCHAR, K_AB.ANGIVELSE_TYPE_CHAR ) ) THEN
      DBMS_SQL.COLUMN_VALUE ( n_cursor, 1, f_sammenlikningsverdi );
   ELSIF ( f_typeangivelse = K_AB.ANGIVELSE_TYPE_NUMBER ) THEN
      DBMS_SQL.COLUMN_VALUE ( n_cursor, 1, n_sammenlikningsverdi );
      f_sammenlikningsverdi := TO_CHAR ( n_sammenlikningsverdi );
   ELSIF ( f_typeangivelse = K_AB.ANGIVELSE_TYPE_DATE ) THEN
      DBMS_SQL.COLUMN_VALUE ( n_cursor, 1, d_sammenlikningsverdi );

      -- Setter riktig dato- og/eller tidsformat iht. spesifikasjon
      IF ( r_gyldighetskategori.AB_DATETIME_TIME_C IS NULL ) THEN
         f_sammenlikningsverdi := TO_CHAR ( d_sammenlikningsverdi, K_AB.FORMAT_DATE_TIME );
      ELSIF ( r_gyldighetskategori.AB_DATETIME_TIME_C = K_AB.INDIKATOR_JANEI_NEI ) THEN
         f_sammenlikningsverdi := TO_CHAR ( d_sammenlikningsverdi, K_AB.FORMAT_DATE );
      ELSE
         f_sammenlikningsverdi := TO_CHAR ( d_sammenlikningsverdi, K_AB.FORMAT_TIME );
      END IF;
   END IF;

   -- Lukk cursoren
   DBMS_SQL.CLOSE_CURSOR(n_cursor);

   Zt.Trace ( 'AA0_TJ_03', 'HentSammenlikningsverdi: Stopp' );

   RETURN f_sammenlikningsverdi;

EXCEPTION
   WHEN NO_DATA_FOUND THEN
      Zt.Trace ( 'AA0_TJ_03', 'HentSammenlikningsverdi: Exception' );
      ZtErr.SetError ( 'AA0_TJ_03', E_AVG.FLYBEVEGELSEN_FINNES_IKKE, '[HentSammenlikningsverdi] Flybevegelses-ID ' || TO_CHAR ( f_flybevegelse_id ) || '.');
   WHEN OTHERS THEN
      Zt.Trace ( 'AA0_TJ_03', 'HentSammenlikningsverdi: Exception' );
      ZtErr.SetError ( 'AA0_TJ_03', E_AVG.ANNEN_FEIL, '[HentSammenlikningsverdi] ' || SQLERRM || '.  Flybevegelses-ID ' || TO_CHAR ( f_flybevegelse_id ) || '.');
END HentSammenlikningsverdi;


-----------------------------------------------------------------------------
-- MatchGyldighetsverdi
-----------------------------------------------------------------------------
-- Funksjonen matcher mottatt gyldighetsverdi med sammenlikningsverdien.
-- Matchingen skjer vha. angitt operator, og returverdien er TRUE dersom
-- det er en match, og FALSE ellers.  B�de sammenliknings- og
-- gyldighetsverdien konverteres til opprinnelig datatype f�r sammenlikningen
-- gj�res.
-----------------------------------------------------------------------------
FUNCTION MatchGyldighetsverdi ( r_gyldighetsverdi     IN  AB_VERDIER_GYLDIGHETSOMR%ROWTYPE,
                                f_sammenlikningsverdi IN  AB_VERDIER_GYLDIGHETSOMR.AB_VERDI_VCH%TYPE,
                                f_operator            IN  AB_OPERATORER.AB_OPERATOR_ID%TYPE,
                                f_typeangivelse       IN  VARCHAR2,
                                f_datotid_er_tid      IN  AB_KATEGORIER_GYLDIGHETSOMR.AB_DATETIME_TIME_C%TYPE )
RETURN
   BOOLEAN
IS
   b_match                       BOOLEAN := FALSE;
   d_sammenlikningsverdi         DATE;
   d_dato                        DATE;
   d_dato2                       DATE;

BEGIN
   Zt.Trace ( 'AA0_TJ_03', 'MatchGyldighetsverdi: Start' );

   IF ( f_operator = K_AB.OPERATOR_LIKNER ) THEN
      -- Sammenlikning vha. 'LIKE' gj�res mellom ukonverterte strenger
      b_match := ( f_sammenlikningsverdi LIKE r_gyldighetsverdi.AB_VERDI_VCH );
   ELSIF ( f_operator = K_AB.OPERATOR_LIKNER_IKKE ) THEN
      -- Sammenlikning vha. 'NOT LIKE' gj�res mellom ukonverterte strenger
      b_match := ( f_sammenlikningsverdi NOT LIKE r_gyldighetsverdi.AB_VERDI_VCH );
   ELSIF ( f_typeangivelse IN ( K_AB.ANGIVELSE_TYPE_VARCHAR, K_AB.ANGIVELSE_TYPE_CHAR ) ) THEN
      -- Sammenlikning mellom strenger skjer direkte
      IF ( f_operator = K_AB.OPERATOR_ER_LIK ) THEN
         b_match :=   ( f_sammenlikningsverdi  = r_gyldighetsverdi.AB_VERDI_VCH  );
      ELSIF ( f_operator = K_AB.OPERATOR_ER_ULIK ) THEN
         b_match :=   ( f_sammenlikningsverdi != r_gyldighetsverdi.AB_VERDI_VCH  );
      ELSIF ( f_operator = K_AB.OPERATOR_ER_STOERRE_ENN ) THEN
         b_match :=   ( f_sammenlikningsverdi  > r_gyldighetsverdi.AB_VERDI_VCH  );
      ELSIF ( f_operator = K_AB.OPERATOR_ER_MINDRE_ENN ) THEN
         b_match :=   ( f_sammenlikningsverdi  < r_gyldighetsverdi.AB_VERDI_VCH  );
      ELSIF ( f_operator = K_AB.OPERATOR_ER_MELLOM ) THEN
         b_match := ( ( f_sammenlikningsverdi >= r_gyldighetsverdi.AB_VERDI_VCH  ) AND
                      ( f_sammenlikningsverdi <= r_gyldighetsverdi.AB_VERDI2_VCH )     );
      END IF;
   ELSIF ( f_typeangivelse = K_AB.ANGIVELSE_TYPE_NUMBER ) THEN
      -- Sammenlikning skjer mellom TO_NUMBER-konverterte verdier
      IF ( f_operator = K_AB.OPERATOR_ER_LIK ) THEN
         b_match :=   ( TO_NUMBER ( f_sammenlikningsverdi )  = TO_NUMBER ( r_gyldighetsverdi.AB_VERDI_VCH  ) );
      ELSIF ( f_operator = K_AB.OPERATOR_ER_ULIK ) THEN
         b_match :=   ( TO_NUMBER ( f_sammenlikningsverdi ) != TO_NUMBER ( r_gyldighetsverdi.AB_VERDI_VCH  ) );
      ELSIF ( f_operator = K_AB.OPERATOR_ER_STOERRE_ENN ) THEN
         b_match :=   ( TO_NUMBER ( f_sammenlikningsverdi )  > TO_NUMBER ( r_gyldighetsverdi.AB_VERDI_VCH  ) );
      ELSIF ( f_operator = K_AB.OPERATOR_ER_MINDRE_ENN ) THEN
         b_match :=   ( TO_NUMBER ( f_sammenlikningsverdi )  < TO_NUMBER ( r_gyldighetsverdi.AB_VERDI_VCH  ) );
      ELSIF ( f_operator = K_AB.OPERATOR_ER_MELLOM ) THEN
         b_match := ( ( TO_NUMBER ( f_sammenlikningsverdi ) >= TO_NUMBER ( r_gyldighetsverdi.AB_VERDI_VCH  ) ) AND
                      ( TO_NUMBER ( f_sammenlikningsverdi ) <= TO_NUMBER ( r_gyldighetsverdi.AB_VERDI2_VCH ) )     );
      END IF;
   ELSIF ( f_typeangivelse = K_AB.ANGIVELSE_TYPE_DATE ) THEN
      IF ( f_datotid_er_tid IS NULL ) THEN
         d_sammenlikningsverdi := TO_DATE ( f_sammenlikningsverdi,           K_AB.FORMAT_DATE_TIME );
         d_dato                := TO_DATE ( r_gyldighetsverdi.AB_VERDI_VCH,  K_AB.FORMAT_DATE_TIME );
         d_dato2               := TO_DATE ( r_gyldighetsverdi.AB_VERDI2_VCH, K_AB.FORMAT_DATE_TIME );
      ELSIF ( f_datotid_er_tid = K_AB.INDIKATOR_JANEI_NEI ) THEN
         d_sammenlikningsverdi := TO_DATE ( f_sammenlikningsverdi,           K_AB.FORMAT_DATE );
         d_dato                := TO_DATE ( r_gyldighetsverdi.AB_VERDI_VCH,  K_AB.FORMAT_DATE );
         d_dato2               := TO_DATE ( r_gyldighetsverdi.AB_VERDI2_VCH, K_AB.FORMAT_DATE );
      ELSE
         d_sammenlikningsverdi := TO_DATE ( f_sammenlikningsverdi,           K_AB.FORMAT_TIME );
         d_dato                := TO_DATE ( r_gyldighetsverdi.AB_VERDI_VCH,  K_AB.FORMAT_TIME );
         d_dato2               := TO_DATE ( r_gyldighetsverdi.AB_VERDI2_VCH, K_AB.FORMAT_TIME );
      END IF;

      -- Sammenlikning skjer mellom TO_DATE-konverterte verdier, med spesifiserte formater
      IF ( f_operator = K_AB.OPERATOR_ER_LIK ) THEN
         b_match :=   ( d_sammenlikningsverdi  = d_dato  );
      ELSIF ( f_operator = K_AB.OPERATOR_ER_ULIK ) THEN
         b_match :=   ( d_sammenlikningsverdi != d_dato  );
      ELSIF ( f_operator = K_AB.OPERATOR_ER_STOERRE_ENN ) THEN
         b_match :=   ( d_sammenlikningsverdi  > d_dato  );
      ELSIF ( f_operator = K_AB.OPERATOR_ER_MINDRE_ENN ) THEN
         b_match :=   ( d_sammenlikningsverdi  < d_dato  );
      ELSIF ( f_operator = K_AB.OPERATOR_ER_MELLOM ) THEN
         b_match := ( ( d_sammenlikningsverdi >= d_dato  ) AND
                      ( d_sammenlikningsverdi <= d_dato2 )     );
      END IF;
   END IF;

   Zt.Trace ( 'AA0_TJ_03', 'MatchGyldighetsverdi: Stopp' );

   RETURN b_match;

EXCEPTION
   WHEN OTHERS THEN
      Zt.Trace ( 'AA0_TJ_03', 'MatchGyldighetsverdi: Exception' );
      ZtErr.SetError ( 'AA0_TJ_03', E_AVG.ANNEN_FEIL, '[MatchGyldighetsverdi] ' || SQLERRM || '.  Gyldighetsverdi-ID ' ||
                       TO_CHAR ( r_gyldighetsverdi.AB_VERDI_GYLDIGHETSOMR_ID ) || ', sammenlikningsverdi ' || f_sammenlikningsverdi || '.');
END MatchGyldighetsverdi;


-----------------------------------------------------------------------------
-- BeregnDelavgift
-----------------------------------------------------------------------------
-- Prosedyren beregner og lagrer unna delavgift for �n matchende regel.  Det
-- opprettes �n delavgift for hver regel som matcher, uavhengig av hvilket
-- niv� i regelhierarkiet regelen befinner seg p�.  Akkumulering av
-- delavgifter og beregning av totalavgift pr. avgiftsomr�de, gj�res i
-- fellestjeneste AA0-TJ-02.
-----------------------------------------------------------------------------
PROCEDURE BeregnDelavgift ( r_gyldighetsverdi     IN  AB_VERDIER_GYLDIGHETSOMR%ROWTYPE,
                            r_regeldetaljer       IN  AB_REGEL_DETALJER%ROWTYPE,
                            f_sammenlikningsverdi IN  AB_VERDIER_GYLDIGHETSOMR.AB_VERDI_VCH%TYPE,
                            f_flybevegelse_id     IN  AB_FLYBEVEGELSER.AB_FLYBEVEGELSE_ID%TYPE    )
IS
   r_delavgiftslinje             AB_DELAVGIFTER%ROWTYPE;
   e_plsql_ikke_implementert     EXCEPTION;
   e_beregningssats_mangler      EXCEPTION;

BEGIN
   Zt.Trace ( 'AA0_TJ_03', 'BeregnDelavgift: Start' );

   -- Hent avgiftsomr�det fra regelen
   SELECT   AB_AVGIFTSOMRAADE_ID
   INTO     r_delavgiftslinje.AB_AVGIFTSOMRAADE_ID
   FROM     AB_REGLER
   WHERE    AB_REGEL_ID = r_regeldetaljer.AB_REGEL_ID;

   IF ( r_regeldetaljer.AB_BEREGNINGSMAATE_ID = K_AB.BERMAATE_PLSQL_RUTINE ) THEN
      RAISE e_plsql_ikke_implementert;
   ELSIF ( r_regeldetaljer.AB_BEREGNINGSMAATE_ID = K_AB.BERMAATE_FRITAK ) THEN
      -- Fritaksregel eller -avtale; beregningssats er null
      r_delavgiftslinje.AB_BEREGNINGSSATS_N := 0;
   ELSE
      -- Hent beregningssats fra verdi- eller regeldetalj-niv�, avhengig av hvor den er oppgitt
      IF ( r_regeldetaljer.AB_BEREGNINGSSATS_N IS NOT NULL ) THEN
         r_delavgiftslinje.AB_BEREGNINGSSATS_N := r_regeldetaljer.AB_BEREGNINGSSATS_N;
      ELSIF ( r_gyldighetsverdi.AB_BEREGNINGSSATS_N IS NOT NULL ) THEN
         r_delavgiftslinje.AB_BEREGNINGSSATS_N := r_gyldighetsverdi.AB_BEREGNINGSSATS_N;
      ELSE
         RAISE e_beregningssats_mangler;
      END IF;
   END IF;

   -- Sett beregningsgrunnlag og utf�r multiplikasjon om "Multiplikasjonssats"; sett delavgift lik beregningssats ellers
   IF ( r_regeldetaljer.AB_BEREGNINGSMAATE_ID = K_AB.BERMAATE_MULTIPLIKASJONSSATS ) THEN
      r_delavgiftslinje.AB_BEREGNINGSGRUNNLAG_N := TO_NUMBER ( f_sammenlikningsverdi );
      r_delavgiftslinje.AB_DELAVGIFT_N          := r_delavgiftslinje.AB_BEREGNINGSGRUNNLAG_N * r_delavgiftslinje.AB_BEREGNINGSSATS_N;
   ELSE
      r_delavgiftslinje.AB_BEREGNINGSGRUNNLAG_N := NULL;
      r_delavgiftslinje.AB_DELAVGIFT_N          := r_delavgiftslinje.AB_BEREGNINGSSATS_N;
   END IF;

   -- Opprett delavgiftslinje
   INSERT INTO AB_DELAVGIFTER
      ( AB_DELAVGIFT_ID,
        AB_BEREGNINGSSATS_N,
        AB_BEREGNINGSGRUNNLAG_N,
        AB_BEREGNINGSMAATE_ID,
        AB_SUMMERINGSMAATE_C,
        AB_DELAVGIFT_N,
        AB_REGEL_ID,
        AB_FLYBEVEGELSE_ID,
        AB_AVGIFTSOMRAADE_ID,
        AB_BEHANDLET_C           )
   VALUES
      ( DELA_SEQ.NEXTVAL,
        r_delavgiftslinje.AB_BEREGNINGSSATS_N,
        r_delavgiftslinje.AB_BEREGNINGSGRUNNLAG_N,
        r_regeldetaljer.AB_BEREGNINGSMAATE_ID,
        r_regeldetaljer.AB_SUMMERINGSMAATE_C,
        r_delavgiftslinje.AB_DELAVGIFT_N,
        r_regeldetaljer.AB_REGEL_ID,
        f_flybevegelse_id,
        r_delavgiftslinje.AB_AVGIFTSOMRAADE_ID,
        K_AB.INDIKATOR_JANEI_NEI                   );

   Zt.Trace ( 'AA0_TJ_03', 'BeregnDelavgift: Stopp' );

EXCEPTION
   WHEN e_plsql_ikke_implementert THEN
      Zt.Trace ( 'AA0_TJ_03', 'BeregnDelavgift: Exception' );
      ZtErr.SetError ( 'AA0_TJ_03', E_AVG.PLSQL_IKKE_IMPLEMENTERT, '[BeregnDelavgift] Regel-ID ' || TO_CHAR ( r_regeldetaljer.AB_REGEL_ID ) || '.' );
   WHEN e_beregningssats_mangler THEN
      Zt.Trace ( 'AA0_TJ_03', 'BeregnDelavgift: Exception' );
      ZtErr.SetError ( 'AA0_TJ_03', E_AVG.BEREGNINGSSATS_MANGLER, '[BeregnDelavgift] Regel-ID ' || TO_CHAR ( r_regeldetaljer.AB_REGEL_ID ) || '.' );
   WHEN OTHERS THEN
      Zt.Trace ( 'AA0_TJ_03', 'BeregnDelavgift: Exception' );
      ZtErr.SetError ( 'AA0_TJ_03', E_AVG.ANNEN_FEIL, '[BeregnDelavgift] ' || SQLERRM || '.  Flybevegelses-ID ' || TO_CHAR ( f_flybevegelse_id ) ||
                       ', regel-ID ' || TO_CHAR ( r_regeldetaljer.AB_REGEL_ID ) || '.');
END BeregnDelavgift;


-----------------------------------------------------------------------------
-- MatchGyldighetsomraade
-----------------------------------------------------------------------------
-- Funksjonen matcher mottatt gyldighetsomr�de med gjeldende flybevegelse.
-- Dette gj�res ved � matche tilknyttede gyldighetsverdier inntil ett av dem
-- matcher, eller ikke flere gyldighetsverdier finnes.  Returverdien er TRUE
-- dersom �n gyldighetsverdi matcher, og FALSE om ingen matcher.
-----------------------------------------------------------------------------
FUNCTION MatchGyldighetsomraade ( r_gyldighetsomraade IN  AB_GYLDIGHETSOMR%ROWTYPE,
                                  r_regeldetaljer     IN  AB_REGEL_DETALJER%ROWTYPE,
                                  f_flybevegelse_id   IN  AB_FLYBEVEGELSER.AB_FLYBEVEGELSE_ID%TYPE,
                                  b_beregn_delavgift  IN  BOOLEAN                                   )
RETURN
   BOOLEAN
IS
   b_match                       BOOLEAN := FALSE;
   f_typeangivelse               USER_TAB_COLUMNS.DATA_TYPE%TYPE;
   f_sammenlikningsverdi         AB_VERDIER_GYLDIGHETSOMR.AB_VERDI_VCH%TYPE;
   r_gyldighetskategori          AB_KATEGORIER_GYLDIGHETSOMR%ROWTYPE;

   CURSOR m_gyldighetsverdier IS
      SELECT   *
      FROM     AB_VERDIER_GYLDIGHETSOMR
      WHERE    AB_GYLDIGHETSOMR_ID = r_gyldighetsomraade.AB_GYLDIGHETSOMR_ID
      ORDER BY AB_VERDI_GYLDIGHETSOMR_ID;

BEGIN
   Zt.Trace ( 'AA0_TJ_03', 'MatchGyldighetsomraade: Start' );

   -- Hent kategoridata for gyldighetsomr�det
   SELECT   *
   INTO     r_gyldighetskategori
   FROM     AB_KATEGORIER_GYLDIGHETSOMR
   WHERE    AB_KATEGORI_ID = r_gyldighetsomraade.AB_KATEGORI_ID;

   -- Hent typeangivelse for kolonnen som inneholder sammenlikningsverdien
   SELECT   DATA_TYPE
   INTO     f_typeangivelse
   FROM     USER_TAB_COLUMNS
   WHERE    TABLE_NAME  = 'AB_FLYBEVEGELSER'
      AND   COLUMN_NAME = r_gyldighetskategori.AB_REF_KOLONNE_VCH;

   -- Hent sammenlikningsverdien fra databasen vha. dynamisk SQL
   f_sammenlikningsverdi := HentSammenlikningsverdi ( f_flybevegelse_id, r_gyldighetskategori, f_typeangivelse );

   -- Loop s� lenge det finnes flere gyldighetsverdier og ingen har sl�tt til
   FOR r_gyldighetsverdi IN m_gyldighetsverdier LOOP
      -- Match gyldighetsverdien mot sammenlikningsverdien
      b_match := MatchGyldighetsverdi
                        ( r_gyldighetsverdi, f_sammenlikningsverdi, r_gyldighetsomraade.AB_OPERATOR_ID, f_typeangivelse, r_gyldighetskategori.AB_DATETIME_TIME_C );

      -- Beregn delavgift dersom dette er siste gyldighetsomr�de
      IF ( b_match AND b_beregn_delavgift ) THEN
         BeregnDelavgift ( r_gyldighetsverdi, r_regeldetaljer, f_sammenlikningsverdi, f_flybevegelse_id );
      END IF;

      -- Hopp ut ved match (holder at �n verdi matcher)
      EXIT WHEN ( b_match );
   END LOOP;

   Zt.Trace ( 'AA0_TJ_03', 'MatchGyldighetsomraade: Stopp' );

   RETURN b_match;

EXCEPTION
   WHEN OTHERS THEN
      Zt.Trace ( 'AA0_TJ_03', 'MatchGyldighetsomraade: Exception' );
      ZtErr.SetError ( 'AA0_TJ_03', E_AVG.ANNEN_FEIL, '[MatchGyldighetsomraade] ' || SQLERRM || '.  Flybevegelses-ID ' || TO_CHAR ( f_flybevegelse_id) ||
                        ', gyldighetsomr�de-ID ' || TO_CHAR ( r_gyldighetsomraade.AB_GYLDIGHETSOMR_ID ) || '.' );
END MatchGyldighetsomraade;


-----------------------------------------------------------------------------
-- AA0_TJ_03
-----------------------------------------------------------------------------
-- Tjenesten matcher mottatt regel mot angitt flybevegelse.  Dette gj�res
-- ved � matche hvert tilknyttet gyldighetsomr�de mot flybevegelsen.
-- Returverdien er TRUE dersom alle tilknyttede gyldighetsomr�der matcher, og
-- FALSE ellers.
-----------------------------------------------------------------------------
BEGIN
   Zt.Trace ( 'AA0_TJ_03', 'AA0_TJ_03: Start' );

   -- Hent gjeldende detaljinformasjon om regelen
   IF ( HentRegeldetaljer ( f_denne_regel, f_flybevegelse_id, r_regeldetaljer ) ) THEN
      -- Match alle gyldighetsomr�der som ikke har beregningsindikatoren satt
      FOR r_gyldighetsomraade IN m_gyldighetsomraader LOOP
         -- Match gyldighetsomr�det mot flybevegelsen
         b_match := MatchGyldighetsomraade ( r_gyldighetsomraade, r_regeldetaljer, f_flybevegelse_id, FALSE );

         -- Hopp ut n�r ett gyldighetsomr�de ikke matcher (alle skal matche)
         EXIT WHEN ( NOT b_match );
      END LOOP;

      IF ( b_match AND b_beregn_delavgift ) THEN
         -- Hent gyldighetsomr�det som har beregningsindikatoren satt
         SELECT   *
         INTO     r_siste_gyldighetsomraade
         FROM     AB_GYLDIGHETSOMR
         WHERE    AB_REGEL_DETALJ_ID       = r_regeldetaljer.AB_REGEL_DETALJ_ID
            AND   AB_BEREGNINGSINDIKATOR_C = K_AB.INDIKATOR_JANEI_JA;

         -- Match siste gyldighetsomr�det
         b_match := MatchGyldighetsomraade ( r_siste_gyldighetsomraade, r_regeldetaljer, f_flybevegelse_id, TRUE );
      END IF;
   ELSE
      -- Regelens gyldighetsperiode omfatter ikke flygningsdatoen
      b_match := FALSE;
   END IF;

   Zt.Trace ( 'AA0_TJ_03', 'AA0_TJ_03: Stopp' );

   RETURN b_match;

EXCEPTION
   WHEN NO_DATA_FOUND THEN
      Zt.Trace ( 'AA0_TJ_03', 'AA0_TJ_03: Exception' );
      ZtErr.SetError ( 'AA0_TJ_03', E_AVG.BER_INDIKATOR_MANGLER, '[Hovedl�kke] Regel-ID ' || TO_CHAR ( f_denne_regel ) || '.' );
   WHEN TOO_MANY_ROWS THEN
      Zt.Trace ( 'AA0_TJ_03', 'AA0_TJ_03: Exception' );
      ZtErr.SetError ( 'AA0_TJ_03', E_AVG.BER_INDIKATOR_IKKE_ENTYDIG, '[Hovedl�kke] Regel-ID ' || TO_CHAR ( f_denne_regel ) || '.' );
   WHEN OTHERS THEN
      Zt.Trace ( 'AA0_TJ_03', 'AA0_TJ_03: Exception' );
      ZtErr.SetError ( 'AA0_TJ_03', E_AVG.ANNEN_FEIL, '[Hovedl�kke] ' || SQLERRM || '.  Flybevegelses-ID ' || TO_CHAR ( f_flybevegelse_id ) ||
                       ', regel-ID ' || TO_CHAR ( f_denne_regel ) || '.' );
END AA0_TJ_03;
/

