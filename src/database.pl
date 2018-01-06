%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -*- Mode: Prolog -*- %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% database.pl --- 
%%% Author          : Anders Blehr
%%% Created On      : Fri Apr  3 12:23:53 1992
%%% Last Modified By: Anders Blehr
%%% Last Modified On: Sun May  3 11:28:53 1992
%%% RCS revision    : $Revision: 1.9 $ $Locker: blehr $
%%% Status          : Under development
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Rules

person(X) :- man(X).
person(X) :- woman(X).

name(X) :- man(X).
name(X) :- woman(X).
name(X) :- place(X).

place(X) :- country(X).
place(X) :- city(X).

dead(X) :- not lives(X).

year(X) :-
	number(X),
	X >= 1900,
	X =< 2000.

time(X) :- year(X).

% Facts (nouns)

man(ali).
man(anders).
man(haakon).
man(john).
man(ola).
man(otto).
man(peter).

woman(barbro).
woman(brit).
woman(chakra).
woman(gunhild).
woman(jane).
woman(kari).
woman(kristin).
woman(mary).

city(bergen).
city(brussel).
city(london).
city(leuven).
city(paris).
city(rome).

country(belgium).
country(england).
country(france).
country(germany).
country(italy).
country(norway).

place(europe).

% Relations (verbs)

live(ali).
live(anders).
live(barbro).
live(brit).
live(gunhild).
live(haakon).
live(jane).
live(john).
live(kari).
live(kristin).
live(mary).
live(ola).
live(otto).
live(peter).
