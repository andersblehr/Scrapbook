CREATE OR REPLACE PACKAGE K_AB
IS
   
   ANGIVELSE_TYPE_VARCHAR              CONSTANT USER_TAB_COLUMNS.DATA_TYPE%TYPE                         := 'VARCHAR2';
   ANGIVELSE_TYPE_CHAR                 CONSTANT USER_TAB_COLUMNS.DATA_TYPE%TYPE                         := 'CHAR';
   ANGIVELSE_TYPE_NUMBER               CONSTANT USER_TAB_COLUMNS.DATA_TYPE%TYPE                         := 'NUMBER';
   ANGIVELSE_TYPE_DATE                 CONSTANT USER_TAB_COLUMNS.DATA_TYPE%TYPE                         := 'DATE';

   AVGOMRAADE_GENERELT                 CONSTANT AB_AVGIFTSOMRAADER.AB_AVGIFTSOMRAADE_ID%TYPE            := '00';
   AVGOMRAADE_START                    CONSTANT AB_AVGIFTSOMRAADER.AB_AVGIFTSOMRAADE_ID%TYPE            := '01';
   AVGOMRAADE_STOEY                    CONSTANT AB_AVGIFTSOMRAADER.AB_AVGIFTSOMRAADE_ID%TYPE            := '02';
   AVGOMRAADE_NATT                     CONSTANT AB_AVGIFTSOMRAADER.AB_AVGIFTSOMRAADE_ID%TYPE            := '03';
   AVGOMRAADE_PASSASJER                CONSTANT AB_AVGIFTSOMRAADER.AB_AVGIFTSOMRAADE_ID%TYPE            := '04';
   AVGOMRAADE_UNDERVEIS                CONSTANT AB_AVGIFTSOMRAADER.AB_AVGIFTSOMRAADE_ID%TYPE            := '05';

   AVSENDER_MOTTAKER_AB                CONSTANT AB_BATCHINFO.AB_AVSENDER_MOTTAKER_VCH%TYPE              := 'AB';

   BER_STATUS_NY                       CONSTANT AB_BEREGNINGSSTATUSER.AB_BEREGNINGSSTATUS_VCH%TYPE      := '-';
-- De følgende tre statusene skal bare finnes på FB-siden (FB_FLYBEVEGELSER):
   BER_STATUS_FEIL                     CONSTANT AB_BEREGNINGSSTATUSER.AB_BEREGNINGSSTATUS_VCH%TYPE      := 'FEIL';
   BER_STATUS_KLARAB                   CONSTANT AB_BEREGNINGSSTATUSER.AB_BEREGNINGSSTATUS_VCH%TYPE      := 'KLARAB';
   BER_STATUS_OVERAB                   CONSTANT AB_BEREGNINGSSTATUSER.AB_BEREGNINGSSTATUS_VCH%TYPE      := 'OVERAB';

   BER_STATUS_MOTTATT                  CONSTANT AB_BEREGNINGSSTATUSER.AB_BEREGNINGSSTATUS_VCH%TYPE      := 'MOTTAB';
   BER_STATUS_AVGBEREGN                CONSTANT AB_BEREGNINGSSTATUSER.AB_BEREGNINGSSTATUS_VCH%TYPE      := 'AVGBER';
   BER_STATUS_REBEREGN                 CONSTANT AB_BEREGNINGSSTATUSER.AB_BEREGNINGSSTATUS_VCH%TYPE      := 'REBER';
   BER_STATUS_MOTTATT_REBEREGN         CONSTANT AB_BEREGNINGSSTATUSER.AB_BEREGNINGSSTATUS_VCH%TYPE      := 'MOTTRB';
   BER_STATUS_DELVIS_FAKT              CONSTANT AB_BEREGNINGSSTATUSER.AB_BEREGNINGSSTATUS_VCH%TYPE      := 'DELFAK';
   BER_STATUS_FAKTURERT                CONSTANT AB_BEREGNINGSSTATUSER.AB_BEREGNINGSSTATUS_VCH%TYPE      := 'FAKT';
   BER_STATUS_DELVIS_KRED              CONSTANT AB_BEREGNINGSSTATUSER.AB_BEREGNINGSSTATUS_VCH%TYPE      := 'DELKRE';
   BER_STATUS_KREDITERT                CONSTANT AB_BEREGNINGSSTATUSER.AB_BEREGNINGSSTATUS_VCH%TYPE      := 'KRED';

   BERMAATE_FASTSATS                   CONSTANT AB_BEREGNINGSMAATER.AB_BEREGNINGSMAATE_ID%TYPE          := 'FA';
   BERMAATE_MIMIMUMSSATS               CONSTANT AB_BEREGNINGSMAATER.AB_BEREGNINGSMAATE_ID%TYPE          := 'MI';
   BERMAATE_MULTIPLIKASJONSSATS        CONSTANT AB_BEREGNINGSMAATER.AB_BEREGNINGSMAATE_ID%TYPE          := 'MU';
   BERMAATE_PLSQL_RUTINE               CONSTANT AB_BEREGNINGSMAATER.AB_BEREGNINGSMAATE_ID%TYPE          := 'PL';
   BERMAATE_PROSENTSATS                CONSTANT AB_BEREGNINGSMAATER.AB_BEREGNINGSMAATE_ID%TYPE          := 'PR';
   BERMAATE_FRITAK                     CONSTANT AB_BEREGNINGSMAATER.AB_BEREGNINGSMAATE_ID%TYPE          := 'FR';

   EC_STATUS_NY                        CONSTANT AB_EC_STATUSER.AB_EC_STATUS_VCH%TYPE                    := '-';
   EC_STATUS_MOTTATT                   CONSTANT AB_EC_STATUSER.AB_EC_STATUS_VCH%TYPE                    := 'MOTTEC';
   EC_STATUS_TIL_EC                    CONSTANT AB_EC_STATUSER.AB_EC_STATUS_VCH%TYPE                    := 'TILEC';
   EC_STATUS_IKKE_EC                   CONSTANT AB_EC_STATUSER.AB_EC_STATUS_VCH%TYPE                    := 'IKKEEC';
   EC_STATUS_SENDT                     CONSTANT AB_EC_STATUSER.AB_EC_STATUS_VCH%TYPE                    := 'SENDEC';
   EC_STATUS_RE_MOTTATT                CONSTANT AB_EC_STATUSER.AB_EC_STATUS_VCH%TYPE                    := 'RMOTEC';
   EC_STATUS_RE_TIL_EC                 CONSTANT AB_EC_STATUSER.AB_EC_STATUS_VCH%TYPE                    := 'RTILEC';
   EC_STATUS_RESENDT                   CONSTANT AB_EC_STATUSER.AB_EC_STATUS_VCH%TYPE                    := 'RSENEC';

   EC_INTRO_KORR_INTRODUKSJON          CONSTANT AB_OVERSENDTE_EC.AB_INTRODUKSJON_KORREKSJON_VCH%TYPE    := 'F';
   EC_INTRO_KORR_KORREKSJON            CONSTANT AB_OVERSENDTE_EC.AB_INTRODUKSJON_KORREKSJON_VCH%TYPE    := 'C';

   EC_OPERATOR_DEFAULT                 CONSTANT AB_OVERSENDTE_EC.AB_OPERATOR_VCH%TYPE                   := 'Z';
   EC_RCO_COLLECTOR_NORWAY             CONSTANT AB_HEADERE_FOOTERE_EC.AB_RCO_COLLECTOR_CODE_VCH%TYPE    := 'EN';

   EC_UNNTAKSKODE_IKKE_MIL_MEDLEM      CONSTANT AB_FLYBEVEGELSER.AB_ECUNNTAKSKODE_OVERSTYRT_VCH%TYPE    := 'X';
   EC_UNNTAKSKODE_MIL_MEDLEM           CONSTANT AB_FLYBEVEGELSER.AB_ECUNNTAKSKODE_OVERSTYRT_VCH%TYPE    := 'M';
   EC_UNNTAKSKODE_KALIBRERING          CONSTANT AB_FLYBEVEGELSER.AB_ECUNNTAKSKODE_OVERSTYRT_VCH%TYPE    := 'N';
   EC_UNNTAKSKODE_TRAINING             CONSTANT AB_FLYBEVEGELSER.AB_ECUNNTAKSKODE_OVERSTYRT_VCH%TYPE    := 'T';
   EC_UNNTAKSKODE_VFR                  CONSTANT AB_FLYBEVEGELSER.AB_ECUNNTAKSKODE_OVERSTYRT_VCH%TYPE    := 'V';
   EC_UNNTAKSKODE_ANNEN                CONSTANT AB_FLYBEVEGELSER.AB_ECUNNTAKSKODE_OVERSTYRT_VCH%TYPE    := 'Z';
   
   FAKTURASTED_LV                      CONSTANT AB_FAKTURASTEDER.AB_FAKTURASTED_ID%TYPE                 := 'LV';
   FAKTURASTED_EC                      CONSTANT AB_FAKTURASTEDER.AB_FAKTURASTED_ID%TYPE                 := 'LV';

   FILNAVN_UTTREKK_EC_PREFIKS          CONSTANT VARCHAR2(10)                                            := 'AB_EC';
   FILNAVN_UTTREKK_EC_FILTYPE          CONSTANT VARCHAR2(10)                                            := '.txt';

   FIL_UTSENDT                         CONSTANT AB_BATCHINFO.AB_UTSENDT_MOTTATT_VCH%TYPE                := 'S';
   FIL_MOTTATT                         CONSTANT AB_BATCHINFO.AB_UTSENDT_MOTTATT_VCH%TYPE                := 'M';

   FLYGNING_IFR1                       CONSTANT AB_FLYBEVEGELSER.AB_VFR_VCH%TYPE                        := 'I';
   FLYGNING_IFR2                       CONSTANT AB_FLYBEVEGELSER.AB_VFR_VCH%TYPE                        := 'N';
   FLYGNING_IFR3                       CONSTANT AB_FLYBEVEGELSER.AB_VFR_VCH%TYPE                        := 'I';
   FLYGNING_IFR4                       CONSTANT AB_FLYBEVEGELSER.AB_VFR_VCH%TYPE                        := 'I';
   FLYGNING_VFR1                       CONSTANT AB_FLYBEVEGELSER.AB_VFR_VCH%TYPE                        := 'V';
   FLYGNING_VFR2                       CONSTANT AB_FLYBEVEGELSER.AB_VFR_VCH%TYPE                        := 'J';
   FLYGNING_VFR3                       CONSTANT AB_FLYBEVEGELSER.AB_VFR_VCH%TYPE                        := 'V';
   FLYGNING_VFR4                       CONSTANT AB_FLYBEVEGELSER.AB_VFR_VCH%TYPE                        := 'V';
   FLYGNING_IFR_VFR                    CONSTANT AB_FLYBEVEGELSER.AB_VFR_VCH%TYPE                        := 'IV';
   FLYGNING_VFR_IFR                    CONSTANT AB_FLYBEVEGELSER.AB_VFR_VCH%TYPE                        := 'VI';

   FLYGNINGSART_KONT_SOKKEL            CONSTANT AB_FLYBEVEGELSER.AB_FLYGNINGENS_ART_VCH%TYPE            := '04';

   FORMAT_DATE                         CONSTANT VARCHAR2(20)                                            := 'DDMMYYYY';
   FORMAT_TIME                         CONSTANT VARCHAR2(20)                                            := 'HH24:MI';
   FORMAT_DATE_TIME                    CONSTANT VARCHAR2(20)                                            := 'DDMMYYYY HH24:MI';

   FORMAT_TIME_TIL_EC                  CONSTANT VARCHAR2(20)                                            := 'HH24MI';
   FORMAT_DATE_BATCH_NR                CONSTANT VARCHAR2(20)                                            := 'DDD';
   FORMAT_DATE_EC_HEADER_FOOTER        CONSTANT VARCHAR2(20)                                            := 'DDMMYY';
   FORMAT_DATE_TIME_FILNAVN            CONSTANT VARCHAR2(20)                                            := '_YYYYMMDD_HH24MISS_';

   FRITAKSKODE_AARSKORT                CONSTANT AB_FRITAKSKODER.AB_FRITAKSKODE_ID%TYPE                  := 'Å-kort';
   FRITAKSKODE_UKEKORT                 CONSTANT AB_FRITAKSKODER.AB_FRITAKSKODE_ID%TYPE                  := 'U-kort';
   FRITAKSKODE_AVG_BER_NULL            CONSTANT AB_FRITAKSKODER.AB_FRITAKSKODE_ID%TYPE                  := 'Null';
   FRITAKSKODE_DELVIS_FRITATT          CONSTANT AB_FRITAKSKODER.AB_FRITAKSKODE_ID%TYPE                  := 'Delvis';

   FOOTER_EC_START                     CONSTANT VARCHAR2(3)                                             := 'END';
   FOOTER_EC_SLUTT                     CONSTANT VARCHAR2(1)                                             := '.';
   FOOTER_EC_DEFAULT_KOMMENTAR         CONSTANT VARCHAR2(1)                                             := '<';

   HEADER_EC_START                     CONSTANT VARCHAR2(1)                                             := '(';
   HEADER_EC_SLUTT                     CONSTANT VARCHAR2(1)                                             := '.';
   HEADER_EC_DEFAULT_KOMMENTAR         CONSTANT VARCHAR2(1)                                             := '<';

   ICAO_LUFTHAVN_NORSK                 CONSTANT AB_FLYBEVEGELSER.AB_LUFTHAVN_DEP_ICAO_VCH%TYPE          := 'EN%';

   ID_REGEL_NULLREGEL                  CONSTANT AB_REGLER.AB_REGEL_ID%TYPE                              := 0;

   INDIKATOR_DEBETKREDIT_DEBET         CONSTANT AB_AVGIFTSLINJER.AB_IND_DEBET_KREDIT_VCH%TYPE           := 'Faktura';
   INDIKATOR_DEBETKREDIT_KREDIT        CONSTANT AB_AVGIFTSLINJER.AB_IND_DEBET_KREDIT_VCH%TYPE           := 'Kreditnota';

   INDIKATOR_JANEI_JA                  CONSTANT CHAR(1)                                                 := 'J';
   INDIKATOR_JANEI_NEI                 CONSTANT CHAR(1)                                                 := 'N';

   INDIKATOR_LUFTHAVN_DEP              CONSTANT AB_AVGIFTSOMRAADER.AB_LUFTHAVN_KOSTNAD_VCH%TYPE         := 'DEP';
   INDIKATOR_LUFTHAVN_ARR              CONSTANT AB_AVGIFTSOMRAADER.AB_LUFTHAVN_KOSTNAD_VCH%TYPE         := 'ARR';
   INDIKATOR_LUFTHAVN_INGEN            CONSTANT AB_AVGIFTSOMRAADER.AB_LUFTHAVN_KOSTNAD_VCH%TYPE         := 'LV';

   INDIKATOR_UTS_MOTT_UTSENDT          CONSTANT AB_BATCHINFO.AB_UTSENDT_MOTTATT_VCH%TYPE                := 'U';
   INDIKATOR_UTS_MOTT_MOTTATT          CONSTANT AB_BATCHINFO.AB_UTSENDT_MOTTATT_VCH%TYPE                := 'M';

   KATEGORI_REGEL_REGEL                CONSTANT AB_REGLER.AB_KATEGORI_VCH%TYPE                          := 'R';
   KATEGORI_REGEL_AVTALE               CONSTANT AB_REGLER.AB_KATEGORI_VCH%TYPE                          := 'A';
   KATEGORI_REGEL_EC                   CONSTANT AB_REGLER.AB_KATEGORI_VCH%TYPE                          := 'E';

   LEDETEKST_FLERE                     CONSTANT VARCHAR2(10)                                            := 'Flere';

   LENGDE_SAMMENLIKNINGSVERDI_VCH      CONSTANT NUMBER(2)                                               := 60;

   LEN_REC_EC_SEKVENSNUMMER            CONSTANT NUMBER(2)                                               := 4;
   LEN_REC_EC_LUFTHAVN                 CONSTANT NUMBER(2)                                               := 4;
   LEN_REC_EC_KALLESIGNAL              CONSTANT NUMBER(2)                                               := 9;
   LEN_REC_EC_FLYTYPE                  CONSTANT NUMBER(2)                                               := 7;
   LEN_REC_EC_OPERATOR                 CONSTANT NUMBER(2)                                               := 3;
   LEN_REC_EC_REGMERKE                 CONSTANT NUMBER(2)                                               := 9;
   LEN_REC_EC_MERKNAD                  CONSTANT NUMBER(2)                                               := 20;
   LEN_REC_EC_COUNT_FOOTER             CONSTANT NUMBER(2)                                               := 4;

   LINJETYPE_AUTOMATISK                CONSTANT AB_AVGIFTSLINJER.AB_LINJETYPE_VCH%TYPE                  := 'Automatisk';

   MODUS_FILAKSESS_SKRIV               CONSTANT CHAR(1)                                                 := 'w';

   NODE_NULLNODE                       CONSTANT AB_AVGIFTSBEREGNINGSSTEG.AB_DENNE_NODE_ID%TYPE          := '0';

   OPERATOR_ER_LIK                     CONSTANT AB_OPERATORER.AB_OPERATOR_ID%TYPE                       := 'EQ';
   OPERATOR_ER_STOERRE_ENN             CONSTANT AB_OPERATORER.AB_OPERATOR_ID%TYPE                       := 'GT';
   OPERATOR_ER_MINDRE_ENN              CONSTANT AB_OPERATORER.AB_OPERATOR_ID%TYPE                       := 'LT';
   OPERATOR_ER_MELLOM                  CONSTANT AB_OPERATORER.AB_OPERATOR_ID%TYPE                       := 'BT';
   OPERATOR_LIKNER                     CONSTANT AB_OPERATORER.AB_OPERATOR_ID%TYPE                       := 'LK';
   OPERATOR_ER_ULIK                    CONSTANT AB_OPERATORER.AB_OPERATOR_ID%TYPE                       := 'NQ';
   OPERATOR_LIKNER_IKKE                CONSTANT AB_OPERATORER.AB_OPERATOR_ID%TYPE                       := 'NL';

   PADDING_NUMERIC                     CONSTANT CHAR                                                    := '0';
   PADDING_ALPHANUMERIC                CONSTANT CHAR                                                    := ' ';

   PARAMETER_FA_TRAINING               CONSTANT AB_PARAMETRE.AB_PARAMETER_ID%TYPE                       := 'FA_TRAINING';
   PARAMETER_RM_KALIBRERING            CONSTANT AB_PARAMETRE.AB_PARAMETER_ID%TYPE                       := 'RM_KALIBRERING';

   RETURKODE_NIVAA_FERDIG              CONSTANT AB_AVGIFTSBEREGNINGSSTEG.AB_REF_NESTE_STEG_TREFF_N%TYPE := 998;
   RETURKODE_FERDIG                    CONSTANT AB_AVGIFTSBEREGNINGSSTEG.AB_REF_NESTE_STEG_TREFF_N%TYPE := 999;

   SEKVENSNUMMER_START                 CONSTANT AB_OVERFOERINGSKALENDRE.AB_SISTE_SEKVENSNUMMER_VCH%TYPE := '0000';

   STEGNUMMER_SLUTT                    CONSTANT AB_AVGIFTSBEREGNINGSSTEG.AB_REF_NESTE_STEG_TREFF_N%TYPE := 900;

   SQLCODE_MASK                        CONSTANT VARCHAR2(8)                                             := '999999';

   SUMMERINGSMAATE_PLUSS               CONSTANT AB_BEREGNINGSMAATER.AB_SUMMERINGSMAATE_C%TYPE           := '+';
   SUMMERINGSMAATE_MINUS               CONSTANT AB_BEREGNINGSMAATER.AB_SUMMERINGSMAATE_C%TYPE           := '-';

   TYPE_REGEL_FRITAK                   CONSTANT AB_REGLER.AB_TYPE_ID%TYPE                               := 'FR';
   TYPE_REGEL_HOVED                    CONSTANT AB_REGLER.AB_TYPE_ID%TYPE                               := 'HO';
   TYPE_REGEL_MINIMUM                  CONSTANT AB_REGLER.AB_TYPE_ID%TYPE                               := 'MI';
   TYPE_REGEL_RABATT                   CONSTANT AB_REGLER.AB_TYPE_ID%TYPE                               := 'RA';
   TYPE_REGEL_TILLEGG                  CONSTANT AB_REGLER.AB_TYPE_ID%TYPE                               := 'TI';
   TYPE_REGEL_UNNTAK                   CONSTANT AB_REGLER.AB_TYPE_ID%TYPE                               := 'UN';

   UTTREKK_EC_NORMAL                   CONSTANT VARCHAR2(3)                                             := 'NOR';
   UTTREKK_EC_TILLEGG                  CONSTANT VARCHAR2(3)                                             := 'ADD';
   
   VAL_AB_INNLAST                      CONSTANT NUMBER                                                  := 1;
   VAL_VURDER_SENDING                  CONSTANT NUMBER                                                  := 2;
   VAL_UTTREKK_EC                      CONSTANT NUMBER                                                  := 3;

   VAL_MAN_OVERSTYRING                 CONSTANT NUMBER                                                  := 0;
   VAL_AVGIFTSBEREGNING                CONSTANT NUMBER                                                  := 2;
   VAL_UTTREKK_OA                      CONSTANT NUMBER                                                  := 3;

   ZTINI_SEC_FILE_LOCATIONS            CONSTANT VARCHAR(64)                                             := 'FileLocations';
   ZTINI_ID_UTTREKK_EC                 CONSTANT VARCHAR(64)                                             := 'AbToEcFiles';
   
END;
/
