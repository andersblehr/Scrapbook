%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -*- Mode: Prolog -*- %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% readin.pl --- 
%%% Author          : Tore Amble
%%% Created On      : Sun May  5 1991
%%% Last Modified By: Anders Blehr
%%% Last Modified On: Mon Apr 27 10:09:19 1992
%%% RCS revision    : $Revision: 1.8 $ $Locker: blehr $
%%% Status          : Working
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

read_sentence(user,P) :- !,
	ttyflush,
	read_in(P).

read_sentence(_,P) :-
	read_in(P),
	doing(P,0),
	write(' */'),
	nl.

%%% Read a Sentence

read_in(P) :-
	initread(L),
	words(P,L,[]),!.

read_line(P) :-
	readline(L),
	words(P,L,[]). %%  TA-900606

initread([K1|U]) :-
	get(K1),
	readrest(K1,U).

readrest(A,[K1|U]) :- 
	appostrophe(A),!,
	get0(K1),
	readrestquote(A,K1,U).

readrest(T,[]) :- 
	term_char(T),!,  %% .?! read outside quote
	to_nl.

readrest(C,[]) :-
	comment_char(C),!,
	to_nl.

readrest(K,[K1|U]) :-
	K=<32,!,
	get(K1),
	readrest(K1,U).

readrest(_,[K2|U]) :-
	get0(K2),
	readrest(K2,U).

readrestquote(A,A,[K1|U]) :-!, %% found matching appostrophe
	get(K1),
	readrest(K1,U).

readrestquote(A,_,[K1|U]) :- !, %% still inside quotes
	get0(K1),
	readrestquote(A,K1,U).    

readline([K|R]) :-
	get0(K),
	\+ K=10,!, % CR
	readline(R).

readline([]).

comment_char(37). %-)

term_char(33).
term_char(46).
term_char(63).

words([V|U]) --> 
	wordc(V),!,
	blanks,
	words(U).

words([]) --> [].

wordc(W) --> word1(CL,Type),{w01(CL,Type,W)}.

w01(CL,V,nb(U)) :-
	var(V),!,
	name(U,CL). % atom_chars(U,CL).

w01(CL,quote,quote(U)) :- !,atom_chars(U,CL).
w01(CL,_,U) :- !,atom_chars(U,CL).

word01([X|Y],Type) --> 
	idchar(X,Type),
	word01(Y,Type).

word01([],_) --> [].

idchar(X,alpha) --> [C],{lc(C,X)}.
idchar(X,alpha) --> [X],{sign(X)}.
idchar(X,_) --> [X],{digit(X)}.

word1([X|Y],Type) --> 
	idchar(X,Type),
	word01(Y,Type).

word1(S,quote) --> 
	[P],{appostrophe(P)},!,
	charstring(S),
	[P].

word1([K],term) --> [K],{not_appostrophe(K)}.

charstring([X|Y]) -->
	[X], {not_appostrophe(X)},
	charstring(Y).

charstring([]) --> [] .  

appostrophe(96). %% `
appostrophe(39). %% '
appostrophe(34). %% "

not_appostrophe(X) :- \+ appostrophe(X).

%% TA

alphanums([K1|U]) --> 
	[K],{alphanum(K,K1)},!,
	alphanums(U).

alphanums([]) --> [].

alphanum(K,K1):-lc(K,K1).
alphanum(K,K):-digit(K).
alphanum(K,K):-sign(K).

digits([K|U]) --> 
	[K],{digsign(K)},!,
	digits(U).

digits([]) --> [].


digsign(X) :- digit(X).
digsign(X) :- sign(X).

digit(K) :-
	K>47,
	K<58.

sign(95) :- !. %% _
sign(45) :- !. %% -

blanks --> 
	[K],{K=<32},!,
	blanks.

blanks --> [].

alpha(Y) --> [X],{lc(X,Y)}.

lc(91,123). %% AE
lc(92,124). %% OE
lc(93,125). %% AA


lc(K,K1) :-
	K>64,
	K<91,!,
	K1 is K\/8'40.

lc(K,K) :- 
	K>96,
	K<126.

to_nl :-
	repeat,
	get0(10),!.

%%% Miscellaneous for File Reading

doing([],_) :- !.
doing([X|L],N0) :-
	out1(X),
	advance(X,N0,N),
	doing(L,N).

out1(nb(X)) :- !,write(X).

out1(A) :- write(A).

advance(X,N0,N) :-
	uses(X,K),
	M is N0+K,
	(M>72,!,
	 nl,
	 N is 0;
	    N is M+1,
	    put(" ")).

uses(nb(X),N) :- !,chars(X,N).
uses(X,N) :- chars(X,N).

chars(X,N) :- atomic(X),!,
	atom_chars(X,L),
	length(L,N).

chars(_,2).
