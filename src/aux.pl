%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -*- Mode: Prolog -*- %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% aux.pl --- 
%%% Author          : Anders Blehr
%%% Created On      : Fri Apr  3 12:24:27 1992
%%% Last Modified By: Anders Blehr
%%% Last Modified On: Sun May  3 11:28:30 1992
%%% RCS revision    : $Revision: 1.19 $ $Locker: blehr $
%%% Status          : Under development
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

forget(X) :-
	retract(X),
	false;
	true.

reset :-
	nl,
	resk,
	resr,
	nl.

resk :- 
	nl,
	forget(known(_)),
	write('known reset'),
	nl.

resr :- 
	nl,
	forget(rule(_)),
	write('rules reset'),
	nl.

summary :-
	nl,
	write_facts,
	nl,
	write_rules.

write_facts :-
	known(X),
	numbervars(X,0,_),
	write('known: '),
	paraphrase(noquery,X),
	nl,
	false;
	true.

write_rules :-
	rule(X),
	numbervars(X,0,_),
	write('rule: '),
	paraphrase(rule,X),
	nl,
	false;
	true.

write_proof([]).
write_proof(Proof) :-
	pop(Prem=>Concl,Proof,Proof1),
	paraphrase(rule,Prem=>Concl),
	nl,
	nl,
	write_proof(Proof1).

write_proof(Proof) :- 
	pop(Subproof,Proof,Proof1),
	paraphrase(noquery,Subproof),
	nl,
	nl,
	write_proof(Proof1).

%%

append([],X,X).
append([X|Y],Z,[X|W]) :- append(Y,Z,W).

pop(X,List,NewList) :- append([X],NewList,List).

member(X,[X|_]).
member(X,[_|Tail]) :- member(X,Tail).

reverse(List,RevList) :- rev(List,[],[],RevList).

rev([],[],RevList,RevList).
rev(List,NList,RevList,NRevList) :-
	pop(Elt,List,TmpList),
	append([Elt],RevList,TmpRevList),
	rev(TmpList,NList,TmpRevList,NRevList).

listify(exists(X):(Rep),ListRep) :-
	listify(Rep,RepList),
	append([exists,'(',X,')',':','('],RepList,TmpList),
	append(TmpList,[')'],ListRep).

listify(which(X):(Rep),ListRep) :-
	listify(Rep,RepList),
	append([which,'(',X,')',':','('],RepList,TmpList),
	append(TmpList,[')'],ListRep).

listify(Rep1&Rep2,ListRep) :-
	listify(Rep1,Rep1List),
	listify(Rep2,Rep2List),
	append(Rep1List,[&],TmpList),
	append(TmpList,Rep2List,ListRep).

listify(Rep,[Rep]) :- atom_term(Rep).

listify(Rep,[P,'(',Q,')']) :- 
	Rep=..[P,Q],
	\+ (P='$VAR').

listify(Rep,ListRep) :-
	Rep=..[P,Q,R],
	listify(Q,QList),
	append([P,'('],QList,TmpList),
	append(TmpList,[',',R,')'],ListRep).

unify(X,X).

get_noun(Rang,Noun,Vars,X) :- pop((Rang,Noun,X),Vars,_),!.
get_noun(Rang,Noun,Vars,X) :-
	\+ (Vars = []),
	pop(_,Vars,Vars1),
	get_noun(Rang,Noun,Vars1,X).

get_article(Noun,an) :-
	convert(Noun,NList),
	pop(C,NList,_),
	vowel(C).

get_article(_,a).

infinitive(Inf,Pres) :- inf(Inf,[C,y],not vowel(C),[C,i,e,s],Pres).
infinitive(Inf,Pres) :- inf(Inf,[C],member(C,[o,s,x,z]),[C,e,s],Pres).
infinitive(Inf,Pres) :- inf(Inf,[C,h],member(C,[c,s]),[C,h,e,s],Pres).
infinitive(Inf,Pres) :- inf(Inf,[],true,[s],Pres).

present(Inf,Pres) :- pres(Inf,[C,y],not vowel(C),[C,i,e,s],Pres).
present(Inf,Pres) :- pres(Inf,[C],member(C,[o,s,x,z]),[C,e,s],Pres).
present(Inf,Pres) :- pres(Inf,[C,h],member(C,[c,s]),[C,h,e,s],Pres).
present(Inf,Pres) :- pres(Inf,[],true,[s],Pres).

inf(Inf,Astring,Condition,Bstring,Pres) :-
	convert(Pres,Preslist),
	append(Base,Bstring,Preslist),
	call(Condition),
	append(Base,Astring,Inflist),
	convert(Inf,Inflist).

pres(Inf,Astring,Condition,Bstring,Pres) :-
	convert(Inf,Inflist),
	append(Base,Astring,Inflist),
	call(Condition),
	append(Base,Bstring,Preslist),
	convert(Pres,Preslist).

convert(X,X1) :-
	var(X1),!,
	name(X,Codes),
	name1(Codes,X1).

convert(X,X1) :-
	var(X),!,
	name1(Codes,X1),
	name(X,Codes).

name1([],[]).
name1([X|Xs],[X1|X1s]) :-
	name(X1,[X]),
	name1(Xs,X1s).

%%

vowel(a).
vowel(e).
vowel(i).
vowel(o).
vowel(u).
