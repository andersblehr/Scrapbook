%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -*- Mode: Prolog -*- %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% solve.pl --- 
%%% Author          : Anders Blehr
%%% Created On      : Sun Apr 12 15:19:00 1992
%%% Last Modified By: Anders Blehr
%%% Last Modified On: Sun May  3 11:31:03 1992
%%% RCS revision    : $Revision: 1.11 $ $Locker: blehr $
%%% Status          : Under development
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

which_solve(which(X):(RepQ&Rep),Quant1,Quant) :-
	known(Rep),
	confirm_quantifier(exists(X):RepQ,Quant1,Quant).

solve(Q,Quant,Quant,Proof1,Proof) :- 
	known(Q),
	append_proof(Q,Proof1,Proof),!.

solve(exists(X):(_&Rep),Quant1,Quant,Proof1,Proof) :-
	nonvar(X),
	solve(Rep,Quant1,Quant,Proof1,Proof),
	rem(_,Rep).

solve(exists(X):(Q&Q1),Quant1,Quant,Proof1,Proof) :- 
	solve(Q1,Quant1,Quant2,Proof1,Proof),
	confirm_quantifier(exists(X):Q,Quant2,Quant),
	rem(_,Q1).

solve(after(X,Y),Quant,Quant,Proof1,Proof) :- 
	\+ solve(before(Y,X),_,_),
	append_proof(after(X,Y),Proof1,Proof),!.

solve(before(X,Y),Quant,Quant,Proof1,Proof) :-
	number(X),
	number(Y),
	X=<Y,
	append_proof(before(X,Y),Proof1,Proof),!.

solve(Q1&Q2,Quant,Quant,Proof1,Proof) :-
	breakup(Q1&Q2,[],Qs),
	\+ (Qs=[]),
	loop_solve(Qs,Quant,Proof1,Proof).

solve(Q,Quant1,Quant,Proof1,Proof) :-
	rule(Q1=>Q),
	remove_instQs(Q1,Q2),
	copy_term(Q2,Q3),
	get_quantifiers(Q2,Quant1,Quant2),
	solve(Q2,Quant2,Quant,Proof1,Proof2),
	numbervars(Q3,0,_),
	append_proof(Q3=>Q,Proof2,Proof),!.

solve(Q,Quant1,Quant,_,_) :-
	subconclusion(Q,Q1),
	remove_instQs(Q1,Q2),
	solve(Q2,Quant1,Quant,[],_),!.

solve(Q,Quant,Quant,Proof1,Proof) :-
	Q=..[W,_],
	member(W,
	[city,country,dead,live,man,person,place,time,woman,year]),
	call(Q),
	append_proof(Q,Proof1,Proof),!.

solve(Q,Quant1,Quant,Proof1,Proof) :-
	\+ Q=exists(_):_,
	Q=..[P,Q1,R],
	nonvar(Q1),
	\+ num_of_vars(Q1,0),
	solve(Q1,Quant1,Quant2,Proof1,Proof2),
	remove_instQs(Q1,Q2),
	Q3=..[P,Q2,R],
	solve(Q3,Quant2,Quant,Proof2,Proof3),
	rem(_,Q3),
	append_proof(Q3,Proof3,Proof),!.

solve(Q,Quant1,Quant,Proof1,Proof) :- 
	\+ Q=before(_,_),
	\+ Q=exists(_):(_&before(_,_)),
	inquire(Q,Quant1,Quant),
	remember_it(Q),
	append_proof(Q,Proof1,Proof),!.

loop_solve([],_,Proof,Proof) :- !.
loop_solve(Qs,Quant,Proof1,Proof) :-
	pop(Q,Qs,RQs),
	solve(Q,Quant,Quant1,Proof1,Proof2),
	loop_solve(RQs,Quant1,Proof2,Proof),!.

loop_solve(Qs,Quant,Proof1,Proof) :-
	pop(Q,Qs,TmpQs),
	append(TmpQs,[Q],NQs),
	loop_solve(NQs,Quant,Proof1,Proof),!.

get_quantifiers(Rep1&Rep2,Quant1,Quant) :-
	get_quantifiers(Rep1,Quant1,Quant2),
	get_quantifiers(Rep2,Quant2,Quant).

get_quantifiers(exists(X):(RepQ&Rep),Quant1,Quant) :- 
	var(X),
	append([(X,RepQ)],Quant1,Quant2),
	get_quantifiers(RepQ&Rep,Quant2,Quant).

get_quantifiers(Rep,Quant1,Quant) :-
	Rep=..[_,Rep1,_],
	nonvar(Rep1),
	get_quantifiers(Rep1,Quant1,Quant).

get_quantifiers(_,Quant,Quant).

confirm_quantifier(exists(X):(Q1&Q2),Quant1,Quant) :-
	solve(Q2,Quant1,Quant2,[],_),
	confirm_quantifier(exists(X):Q1,Quant2,Quant).

confirm_quantifier(exists(_):Q,Quant1,Quant) :- solve(Q,Quant1,Quant,[],_).

breakup(Q1&Q2,Qs,NQs) :-
	append([Q1],Qs,TmpQs),
	breakup(Q2,TmpQs,NQs).

breakup(Q,Qs,NQs) :- append([Q],Qs,NQs).

subconclusion(Q,Q1) :- rule(Q1=>Q&_).
subconclusion(Q,Q1) :- rule(Q1=>_&Q).
subconclusion(Q,Q1) :- rule(Q1=>_&Q&_).

get_var(_,_,[],[]) :- !,fail.
get_var(X,Rep,Quant1,Quant) :- 
	pop((Y,Rep),Quant1,Quant),
	Y==X.

get_var(X,Rep,Quant1,Quant) :-
	pop(Tmp,Quant1,Quant2),
	get_var(X,Rep,Quant2,Quant3),
	append([Tmp],Quant3,Quant).

num_of_vars(Q,N) :-
	copy_term(Q,Q1),
	numbervars(Q1,0,X),
	X=N.

remember_it(Q) :-
	num_of_vars(Q,0),
	rem(_,Q).

remember_it(_).

%%

inquire(exists(X):Q,Quant,Quant) :-
	var(X),
	num_of_vars(exists(X):Q,1),
	ask(exists(X):Q,Quant,_),!.

inquire(Q,Quant1,Quant) :-
	num_of_vars(Q,1),
	append_quantifier(Q,Q1,Quant1,Quant2),
	ask(Q1,Quant2,Quant),!.

inquire(Q,Quant,Quant) :- 
	num_of_vars(Q,0),
	ask(Q,_,_),!.

ask(Rep,_,_) :- known(Rep),!.
ask(exists(X):(RepQ&Rep),Quant1,Quant) :-
	copy_term(which(X):(RepQ&Rep),Q),
	numbervars(Q,0,_),
	get_input(Q,L),
	((L=[nb(Reply)|_];L=[Reply|_]),
	  \+ Reply=no,
	  unify(X,Reply),
	  confirm_quantifier(exists(X):RepQ,Quant1,Quant));
	L=proceed,
	solve(exists(X):(RepQ&Rep),Quant1,Quant,[],_),!.

ask(Q,Quant,Quant) :-
	num_of_vars(Q,0),
	get_input(Q,L),
	L=[yes|_],!.

append_quantifier(exists(X):(_&Rep),Rep,Quant,Quant) :- nonvar(X),!.
append_quantifier(Q,AskableQ,Quant1,Quant) :-
	((Q=..[_,X,_],var(X));(Q=..[_,_,X],var(X))),
	get_var(X,Rep,Quant1,Quant),
	unify(AskableQ,exists(X):(Rep&Q)),!.

append_quantifier(Q,exists(X):(Rep&Q),Quant1,Quant) :-
	Q=..[_,Rep1,_],
	nonvar(Rep1),
	Rep1=..[_,X],
	var(X),
	get_var(X,Rep,Quant1,Quant),!.

append_proof(Q,Proof1,Proof) :-
	copy_term(Q,Q1),
	numbervars(Q1,0,_),
	append([Q1],Proof1,Proof).

get_input(Q,L) :-
	paraphrase(query,Q),
	write('  '),
	read_sentence(user,L1),
	evaluate_input(L1,L).

evaluate_input(L1,proceed) :-
	sentence(subject(X),Rep,Type,L1,[]),
	evaluate(Type,subject(X),Rep),!.

evaluate_input(L,L).
