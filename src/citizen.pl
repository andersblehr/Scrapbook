%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -*- Mode: Prolog -*- %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% citizen.pl --- 
%%% Author          : Anders Blehr
%%% Created On      : Sat Apr  4 13:47:05 1992
%%% Last Modified By: Anders Blehr
%%% Last Modified On: Tue Apr 28 14:45:53 1992
%%% RCS revision    : $Revision: 1.19 $ $Locker: blehr $
%%% Status          : Under development
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

:- consult(grammar).     % grammar
:- consult(aux).         % auxiliary predicates
:- consult(database).    % database
:- consult(dictionary).  % dictionary
:- consult(para).        % paraphrase from LR to NL
:- consult(readin).      % converts text to list format
:- consult(remember).    % asserting rules and extracted facts
:- consult(solve).       % expert system shell

:- dynamic known/1.
:- dynamic rule/1.

run :-
	repeat,
	nl,
	nl,
	write('NRL: '),
	read_sentence(user,List),
	(List=[stop|_];
	    (List=[C|_],
	     member(C,[debug,nodebug,reset,resk,resr,summary]),
	     call(C),
	     run);
	    (sentence(subject(X),Rep,Type,List,[]),
	     prettyprint(Rep),
	     evaluate(Type,subject(X),Rep),
	     nl,
	     run)).

evaluate(query,_,Rep) :- evaluate(Rep).
evaluate(stmt,subject(X),Rep) :- rem(subject(X),Rep).

evaluate(how:Rep1) :- !,
	nl,
	remove_instQs(Rep1,Rep),
	solve(Rep,[],_,[],Proof),
	nl,
	write_proof(Proof),
	nl,
	write('yes'),
	false;
	true,
	nl.

evaluate(which(X):Rep1) :- !,
	nl,
	remove_instQs(which(X):Rep1,Rep),
	which_solve(Rep,[],_),
	write(X),
	nl,
	false;
	true,
	nl.

evaluate(Rep1) :- !,
	nl,
	remove_instQs(Rep1,Rep),
	solve(Rep,[],_,[],_),
	nl,
	write('yes'),
	nl,
	false;
	true,
	nl.

evaluate(_) :-
	nl,
	write('error'),
	nl,
	false;
	true,
	nl.

prettyprint(Rep) :-
	nl,
	nl,
	numbervars(Rep,0,_),
	write(Rep),
	nl,
	nl,
	false; % release bindings
	true.


exists(_):P :- P.

P=>Q :-	not(P&(not Q)).

forall(_):(P=>Q) :- not(P&(not Q)).

X&Y :- 
	known(Y),
	known(X).

not X :- \+ X.
