%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -*- Mode: Prolog -*- %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% grammar.pl --- 
%%% Author          : Anders Blehr
%%% Created On      : Fri Apr  3 12:23:27 1992
%%% Last Modified By: Anders Blehr
%%% Last Modified On: Sun May  3 11:29:56 1992
%%% RCS revision    : $Revision: 1.30 $ $Locker: blehr $
%%% Status          : Under development
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

:- op(900,xfx,=>).
:- op(800,xfy,&).
:- op(700,fx,not).
:- op(300,xfx,:).

sentence(subject(X),Rep,stmt) --> statement(subject(X),Rep),!.
sentence(_,Rep,query) --> query(Rep).

statement(_,Rep1=>Rep2) -->
	[if],
	body(_,Rep1,[],Vars),
	[then],
	body(_,Rep2,Vars,_),
	[.].

statement(subject(X),Rep) --> 
	body(subject(X),Rep,[],_),
	[.].

query(how:Rep) -->
	[how],
	is_does_phrase(Rep).

query(Rep) -->
	wh_pron(X,Rep1,Rep),
	vp_aux(X,Rep1),
	[?],!.

query(Rep) --> is_does_phrase(Rep).

is_does_phrase(Rep) --> is_phrase(Rep).
is_does_phrase(Rep) --> does_phrase(Rep).

is_phrase(Rep) --> 
	aux(be),
	noun_phrase(X,Rep1,Rep2,[],Vars1),
	(comp(X,Rep1);prep_phrase(X,Rep1,Vars1,Vars2)),
	prep_phrases(Rep2,Rep,Vars2,_),
	[?].

does_phrase(Rep) --> 
	aux(do),
	simple_body(_,Rep,[],_),
	[?].

vp_aux(X,Rep) --> verb_phrase(X,Rep,[],_),!.
vp_aux(X,Rep) --> aux_phrase(X,Rep).

aux_phrase(X,Rep) -->
	aux(do),
	trace_vp(X,Rep,[],_).

aux_phrase(_,Rep) -->
	aux(do),
	simple_body(_,Rep,[],_).

aux_phrase(_,Rep) -->
	aux(be),
	noun_phrase(X,Rep1,Rep2,[],_),
	aux_tail(X,Rep1,[],_),
	prep_phrases(Rep2,Rep,[],_).

body(subject(X),Rep,Vars1,Vars) --> simple_body(subject(X),Rep,Vars1,Vars).
body(_,Rep,Vars1,Vars) --> conj_body(Rep,Vars1,Vars).

simple_body(subject(X),Rep,Vars1,Vars) -->
	noun_phrase(X,Rep1,Rep,Vars1,Vars2),
	verb_phrase(X,Rep1,Vars2,Vars).

conj_body(Rep1&Rep2,Vars1,Vars) -->
	simple_body(_,Rep1,Vars1,Vars2),
	[and],
	body(_,Rep2,Vars2,Vars).

noun_phrase(X,Rep1,Rep,Vars1,Vars) -->
	determiner(X,Rep2,Rep1,Rep,Vars1,Vars2),
	np_core(X,Rep2,Vars2,Vars).

noun_phrase(X,Rep,Rep,Vars,Vars) --> simple_np(X,Vars).

np_core(X,Rep,Vars1,Vars) -->
	adjs(X,Rep1,Rep),
	noun(X,Rep2,Vars1,Vars2),
	mod_rel(X,Rep2,Rep1,Vars2,Vars).

verb_phrase(X,Rep,Vars1,Vars) -->
	vp(X,Rep1,Vars1,Vars2),
	prep_phrases(Rep1,Rep,Vars2,Vars).

vp(X,Rep,Vars,Vars) --> intrans_verb(X,Rep).

vp(X,Rep,Vars1,Vars) -->
	trans_verb(X,Y,Rep1),  % love
	noun_phrase(Y,Rep1,Rep,Vars1,Vars). % mary

vp(X,Rep,Vars1,Vars) --> 
	aux(be),
	aux_tail(X,Rep,Vars1,Vars).

vp(X,Rep,Vars1,Vars) --> trace_vp(X,Rep,Vars1,Vars).

aux_tail(X,Rep,Vars,Vars) --> comp(X,Rep).
aux_tail(X,Rep,Vars1,Vars) --> prep_phrase(X,Rep,Vars1,Vars).

trace_vp(Y,Rep,Vars1,Vars) -->
	noun_phrase(X,Rep1,Rep,Vars1,Vars), % mary
	trans_verb(X,Y,Rep1).  % love

mod_rel(_,Rep1,Rep,Vars1,Vars) --> modifier(Rep1,Rep,Vars1,Vars).
mod_rel(X,Rep1,Rep,Vars1,Vars) --> rel_clause(X,Rep1,Rep,Vars1,Vars).

prep_phrases(Rep1,Rep,Vars1,Vars) -->
	prep_phrase(Rep1,Rep2,Vars1,Vars2),
	prep_phrases(Rep2,Rep,Vars2,Vars).

prep_phrases(Rep,Rep,Vars,Vars) --> [].

prep_phrase(Rep1,Rep,Vars1,Vars) -->
	prep(Rep1,Y,Rep2),
	prep_np(Y,Rep2,Rep,Vars1,Vars).

modifier(Rep1,Rep,Vars1,Vars) -->
	mod_prep(Rep1,Y,Rep2),
	mod_np(Y,Rep2,Rep,Vars1,Vars).

mod_np(X,Rep1,Rep2,Vars1,Vars) -->
	prep_det(X,Rep3,Rep1,Rep2,Vars1,Vars2),
	adjs(X,Rep4,Rep3),
	noun(X,Rep5,Vars2,Vars3),
	rel_clause(X,Rep5,Rep4,Vars3,Vars).

mod_np(X,Rep,Rep,Vars,Vars) --> simple_np(X,Vars).

prep_np(X,Rep1,Rep2,Vars1,Vars) -->
	prep_det(X,Rep3,Rep1,Rep2,Vars1,Vars2),
	np_core(X,Rep3,Vars2,Vars).

prep_np(X,Rep,Rep,Vars,Vars) --> simple_np(X,Vars).

simple_np(X,_) --> name(X).
simple_np(X,_) --> year(X).
simple_np(X,_) --> abst_noun(X).
simple_np(X,Vars) --> [this,third,Noun],{get_noun(third,Noun,Vars,X)}.
simple_np(X,Vars) --> [this,other,Noun],{get_noun(other,Noun,Vars,X)}.
simple_np(X,Vars) --> [this,Noun],{get_noun(first,Noun,Vars,X)}.

prep_det(X,Rep1,Rep2,forall(X):(Rep1&Rep2),Vars,Vars) --> [every].
prep_det(X,Rep1,Rep2,exists(X):(Rep1&Rep2),Vars,Vars) --> 
	[a] | [an] | [the] | [some].
prep_det(_,Rep,Rep,Vars,Vars) --> [].

prep_det(X,Rep1,Rep2,exists(X):(Rep1&Rep2),Vars1,Vars) --> [any,third],
	{append([(insert_noun,third)],Vars1,Vars)}.
prep_det(X,Rep1,Rep2,exists(X):(Rep1&Rep2),Vars1,Vars) --> [any,other],
	{append([(insert_noun,other)],Vars1,Vars)}.
prep_det(X,Rep1,Rep2,exists(X):(Rep1&Rep2),Vars1,Vars) --> [any],
	{append([(insert_noun,first)],Vars1,Vars)}.

adjs(X,Rep1,Rep3) --> 
	adj(X,Rep2),
	adjs(X,Rep1&Rep2,Rep3).

adjs(_,Rep,Rep) --> [].

rel_clause(X,Rep1,Rep1&Rep2,Vars1,Vars) --> 
	rel_pron,
	verb_phrase(X,Rep2,Vars1,Vars).

rel_clause(_,Rep,Rep,Vars,Vars) --> [] .

comp(X,Rep) --> adj(X,Rep).
comp(X,Rep) --> ([a] | [an] | [the]),
	np_core(X,Rep,[],_).  

determiner(X,Rep1,Rep2,forall(X):(Rep1=>Rep2),Vars,Vars) --> [every].
determiner(X,Rep1,Rep2,exists(X):(Rep1&Rep2),Vars,Vars) --> [a] | [an] | [the].

determiner(X,Rep1,Rep2,exists(X):(Rep1&Rep2),Vars1,Vars) --> [any,third],
	{append([(insert_noun,third)],Vars1,Vars)}.
determiner(X,Rep1,Rep2,exists(X):(Rep1&Rep2),Vars1,Vars) --> [any,other],
	{append([(insert_noun,other)],Vars1,Vars)}.
determiner(X,Rep1,Rep2,exists(X):(Rep1&Rep2),Vars1,Vars) --> [any],
	{append([(insert_noun,first)],Vars1,Vars)}.

wh_pron(X,Rep,which(X):(time(X)&in(Rep,X))) --> [when].
wh_pron(X,Rep,which(X):(place(X)&in(Rep,X))) --> [where].
wh_pron(X,Rep,which(X):(person(X)&(Rep))) --> [who].
wh_pron(X,Rep,which(X):(Rep1&Rep)) --> [which],
	np_core(X,Rep1,[],_).

rel_pron --> [that] | [who] | [which].

aux(be) --> [is] | [are] | [was] | [were].

aux(do) --> [does] | [did].

noun(X,P,Vars1,Vars) --> [W],
	{noun(W),
	 P=..[W,X],
	 ((pop((insert_noun,Rang),Vars1,Vars2),
	   append([(Rang,W,X)],Vars2,Vars));
	     unify(Vars1,Vars))}.

abst_noun(W) --> [W],{abst_noun(W)}.

trans_verb(X,Y,P) --> [W],
	{(infinitive(I,W),
	  trans_verb(I),
	  P=..[I,X,Y]);
	    (trans_verb(W),
	     P=..[W,X,Y])}.

intrans_verb(X,P) --> [W],
	{(infinitive(I,W),
	  intrans_verb(I),
	  P=..[I,X]);
	    (intrans_verb(W),
	     P=..[W,X])}.

adj(X,P) --> [W],{adj(W),P=..[W,X]}.

prep(Rep1,Rep2,P) --> [W],{prep(W),P=..[W,Rep1,Rep2]}.

mod_prep(Rep1,Rep2,P) --> [W],{mod_prep(W),P=..[W,Rep1,Rep2]}.

name(N) --> [N],{name(N)}.

number(N) --> [nb(N)],{number(N)}.

year(X) --> [nb(X)],{year(X)}.
