%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -*- Mode: Prolog -*- %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% remember.pl --- 
%%% Author          : Anders Blehr
%%% Created On      : Wed Apr 15 19:24:58 1992
%%% Last Modified By: Anders Blehr
%%% Last Modified On: Sun May  3 11:30:53 1992
%%% RCS revision    : $Revision: 1.10 $ $Locker: blehr $
%%% Status          : Under development
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

rem(_,before(_,_)).
rem(_,forall(_):(R1=>R2)) :- remember(rule(R1=>R2)).
rem(_,R1=>R2) :- remember(rule(R1=>R2)).
rem(subject(S),R) :- explode_it(subject(S),known(R)).

remember(X) :-
	copy_term(X,X1),
	numbervars(X1,0,_),
	call(X1),!.

remember(X) :- assert(X).

explode_it(_,known(X)) :- known(X),!.
explode_it(subject(S),known(X)) :- unnest_it(subject(S),X).

unnest_it(subject(S),exists(X):(RepS&Rep1)) :-
	var(S),
	S==X,
	remove_instQs(Rep1,Rep),
	unnest([existensial(X),RepS],Rep,[],_).

unnest_it(subject(S),Rep1) :- 
	remove_instQs(Rep1,Rep),
	unnest([S],Rep,[],_).

unnest(_,X,_,_) :- var(X).
unnest(Subject,Rep1&Rep2,_,_) :-
	unnest(Subject,Rep1,[],_),
	unnest(Subject,Rep2,[],_).

unnest(Subject,exists(X):(Rep1&Rep2),Pairs1,Pairs) :-
	Rep2=..[P,Rep3,Rep4],
	append([existensial(X),Rep1,(P,Rep4)],Pairs1,Pairs2),
	assert_all(Subject,Rep3,Pairs2),
	unnest(Subject,Rep3,Pairs2,Pairs).

unnest(Subject,Rep,Pairs1,Pairs) :-
	Rep=..[P,Rep1,Rep2],
	append([(P,Rep2)],Pairs1,Pairs2),
	assert_all(Subject,Rep1,Pairs2),
	unnest(Subject,Rep1,Pairs2,Pairs).

unnest(Subject,Rep1,Pairs,Pairs) :-
	Rep1=..[_,_],
	append_varsubj(Subject,Rep1,Rep),
	remember(known(Rep)).

unnest(_,_,_,_).

assert_all(_,_,[]).
assert_all(Subject,Rep1,Pairs) :-
	get_prefix(Pairs,Pairs1,Prefix),
	pop((P,Q),Pairs1,Pairs2),
	Rep2=..[P,Rep1,Q],
	make_term(Prefix,Rep2,Rep3),
	append_varsubj(Subject,Rep3,Rep),
	remember(known(Rep)),
	assert_tail(Prefix,Q,Pairs2),
	assert_all(Subject,Rep1,Pairs2).

assert_tail(_,_,[]).
assert_tail(Prefix1,Rep1,Pairs) :-
	get_prefix(Pairs,Pairs1,Prefix2),
	pop((P,Q),Pairs1,Pairs2),
	Rep2=..[P,Rep1,Q],
	make_term(Prefix1,Rep2,Rep3),
	make_term(Prefix2,Rep3,Rep),
	remember(known(Rep)),
	assert_tail(Prefix1,Rep1,Pairs2).

get_prefix(Pairs1,Pairs,exists(X):Rep2) :-
	pop(existensial(X),Pairs1,Pairs2),
	pop(Rep2,Pairs2,Pairs).

get_prefix(Pairs,Pairs,noprefix).

make_term(noprefix,Rep,Rep).
make_term(exists(X):Rep1,Rep2,exists(X):(Rep1&Rep2)).

append_varsubj([existensial(X),RepS],Rep,exists(X):(RepS&Rep)).
append_varsubj([_],Rep,Rep).

remove_instQs(exists(X):(_&Rep1),Rep) :- 
	nonvar(X),
	remove_instQs(Rep1,Rep).

remove_instQs(exists(X):(RepQ&Rep1),exists(X):(RepQ&Rep)) :- 
	remove_instQs(Rep1,Rep).

remove_instQs(Rep1&Rep2,Rep3&Rep4) :-
	remove_instQs(Rep1,Rep3),
	remove_instQs(Rep2,Rep4).

remove_instQs(Rep1,Rep) :-
	Rep1=..[P,Rep2,R],
	nonvar(Rep2),
	remove_instQs(Rep2,Rep3),
	Rep=..[P,Rep3,R].

remove_instQs(Rep,Rep).
