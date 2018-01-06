%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -*- Mode: Prolog -*- %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% candel.pl --- 
%%% Author          : Anders Blehr
%%% Created On      : Sun May 10 13:22:02 1992
%%% Last Modified By: Anders Blehr
%%% Last Modified On: Sun May 10 21:02:00 1992
%%% RCS revision    : $Revision$ $Locker$
%%% Status          : Unknown, Use with caution!
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

:- consult(readin).

run :-
	write('*** Learning by the Candidate Elimination Algorithm ***'),nl,nl,
	get_null_description(G,Attr),
	get_first_example(Attr,S),
	iterate(Attr,G,S).

get_null_description(G,Attr) :- nl,
	write('Supply description features: '),
	read_sentence(user,L),
	extract_null_description(L,[],Descr,[],Attr),
	append([Descr],[],G).

extract_null_description([Feature,'.'],Descr1,Descr,Attr1,Attr) :-
	append(Descr1,[nil],Descr),
	append(Attr1,[Feature],Attr).

extract_null_description([Feature,','|Rest],Descr1,Descr,Attr1,Attr) :-
	append(Descr1,[nil],Descr2),
	append(Attr1,[Feature],Attr2),
	extract_null_description(Rest,Descr2,Descr,Attr2,Attr).

get_first_example(Attr,S) :- nl,
	write('Supply the first positive example'),nl,nl,
	get_example(Attr,[],Ex),
	append([Ex],[],S).

get_example([],Ex,Ex) :- !.
get_example(Attr,Ex1,Ex) :- 
	pop(Feature,Attr,Attr1),
	inquire(Feature,Result),
	append(Ex1,[Result],Ex2),
	get_example(Attr1,Ex2,Ex).

inquire(Feature,Result) :-
	write('    '),
	write(Feature),
	write(': '),
	read_sentence(user,[Result|_]).

iterate(Attr,X,X) :- nl,
	write('Concept description:'),
	output_description(Attr,X),!.

iterate(Attr,G,S) :- nl,
	inquire_sign(Sign),nl,nl,
	get_example(Attr,[],Ex),
	update_G(Sign,Attr,Ex,G,NewG,S),
	update_S(Sign,Ex,S,NewS),nl,
	write('Value of G: '),
	write(NewG),nl,
	write('Value of S: '),
	write(NewS),nl,
	iterate(Attr,NewG,NewS).

inquire_sign(Sign) :-
	write('Is the next example positive or negative (p/n)? '),
	read_sentence(user,[Sign|_]),
	member(Sign,[p,n]).

update_G(p,_,Ex,G1,G,_) :- shrink_G(Ex,G1,[],G).
update_G(n,Attr,Ex,[G1],G,S) :- expand_G(Attr,Ex,[G1],[],G,S).
update_G(n,Attr,Ex,G1,G,S) :- specialize(Attr,Ex,G1,G,S).

shrink_G(_,[],G,G) :- !.
shrink_G(Ex,G1,TmpG1,G) :-
	pop(Descr,G1,G2),
	peval_descr(Ex,Descr,TmpG1,TmpG2),
	shrink_G(Ex,G2,TmpG2,G).

peval_descr(Ex,Descr,TmpG1,TmpG2) :-
	unify(Ex,Descr),
	append(TmpG1,[Descr],TmpG2),!.

peval_descr(_,_,TmpG,TmpG).

expand_G(_,_,[],G,G,_) :- !.
expand_G(Attr,Ex,G1,TmpG1,G,S) :-
	pop(Descr,G1,G2),
	neval_descr(Attr,Ex,Descr,TmpG1,TmpG2,S),
	expand_G(Attr,Ex,G2,TmpG2,G,S).
	
neval_descr(Attr,Ex,Descr1,TmpG1,TmpG2,S) :-
	unify(Ex,Descr1),
	pop(Descr2,S,_),
	expand(Attr,Attr,Ex,Descr2,TmpG1,TmpG2).

expand(_,[],[],[],TmpG,TmpG) :- !.
expand(Attr,Tmp,Ex,Descr,TmpG1,TmpG) :-
	pop(Feature,Tmp,Tmp1),
	pop(Value1,Descr,Descr1),
	pop(Value2,Ex,Ex1),
	eval_feature(Attr,Feature,Value1,Value2,TmpG1,TmpG2),
	expand(Attr,Tmp1,Ex1,Descr1,TmpG2,TmpG).

eval_feature(_,_,Value1,Value2,TmpG,TmpG) :- unify([Value1],[Value2]),!.
eval_feature(Attr,Feature,Value,_,TmpG1,TmpG) :- 
	make_entry(Attr,Feature,Value,[],Entry),
	append(TmpG1,[Entry],TmpG).

make_entry([],_,_,Entry,Entry) :- !.
make_entry(Attr,Feature,Value,Entry1,Entry) :-
	pop(Feature,Attr,Attr1),
	append(Entry1,[Value],Entry2),
	make_entry(Attr1,Feature,Value,Entry2,Entry),!.

make_entry(Attr,Feature,Value,Entry1,Entry) :-
	pop(_,Attr,Attr1),
	append(Entry1,[nil],Entry2),
	make_entry(Attr1,Feature,Value,Entry2,Entry).

specialize(Attr,Ex,G1,G,S) :-
	find_features(G1,GFeatures),
	find_features(S,SFeatures),
	diff(SFeatures,GFeatures,[],Diff),
	find_spec(Attr,Ex,Diff,Result),
	make_G(Attr,Result,G1,G).

find_features([],_) :- !.
find_features(G,Features) :-
	pop(Descr,G,G1),
	find_union(Descr,G1,Features).

find_union(Features,[],Features) :- !.
find_union(Descr1,G,Features) :-
	pop(Descr2,G,G1),
	union(Descr1,Descr2,[],Features1),
	find_union(Features1,G1,Features).

union([],[],Union,Union) :- !.
union(Set1,Set2,Union1,Union) :-
	pop(Elt1,Set1,NSet1),
	pop(Elt2,Set2,NSet2),
	eval_elts(Elt1,Elt2,Result),
	append(Union1,[Result],Union2),
	union(NSet1,NSet2,Union2,Union).

eval_elts(nil,nil,nil) :- !.
eval_elts(nil,Value,Value) :- !.
eval_elts(Value,nil,Value) :- !.
eval_elts(Value,Value,Value).

diff([],[],Diff,Diff) :- !.
diff(Set1,Set2,Diff1,Diff) :-
	pop(Elt1,Set1,NSet1),
	pop(Elt2,Set2,NSet2),
	diff_elts(Elt1,Elt2,Result),
	append(Diff1,[Result],Diff2),
	diff(NSet1,NSet2,Diff2,Diff).

diff_elts(nil,nil,nil) :- !.
diff_elts(nil,Value,Value) :- !.
diff_elts(Value,nil,Value) :- !.
diff_elts(Value,Value,nil).

find_spec([],[],[],nil).
find_spec(Attr,Ex,Diff,Result) :-
	pop(Feature,Attr,Attr1),
	pop(Value,Ex,Ex1),
	pop(Elt,Diff,Diff1),
	(eval_spec(Feature,Value,Elt,Result);
	    find_spec(Attr1,Ex1,Diff1,Result)).

eval_spec(Feature,Value,Elt,(Feature,Elt)) :- \+ unify([Value],[Elt]),!.

make_G(_,_,[],[]) :- !.
make_G(Attr,Spec,G1,G) :-
	pop(Elt1,G1,G2),
	make_elt(Attr,Spec,Elt1,[],Elt),
	make_G(Attr,Spec,G2,G3),
	append([Elt],G3,G).

make_elt(Attr,(Feature,Value),OldElt1,Elt1,Elt) :-
	pop(Feature,Attr,_),
	pop(_,OldElt1,OldElt),
	append(Elt1,[Value],Elt2),
	append(Elt2,OldElt,Elt).

make_elt(Attr,Spec,OldElt,Elt1,Elt) :-
	pop(_,Attr,Attr1),
	pop(Tmp,OldElt,OldElt1),
	append(Elt1,[Tmp],Elt2),
	make_elt(Attr1,Spec,OldElt1,Elt2,Elt).

update_S(p,Ex,S,NewS) :- generalize(Ex,S,[],NewS).
update_S(n,Ex,S,NewS) :- remove(Ex,S,[],NewS).

generalize(_,[],NewS,NewS) :- !.
generalize(Ex,S,TmpS,NewS) :-
	pop(Descr,S,S1),
	eval_descr(Ex,Descr,TmpS,TmpS1),
	generalize(Ex,S1,TmpS1,NewS).

eval_descr(Ex,Descr,TmpS1,TmpS) :-
	unify(Ex,Descr),
	append(TmpS1,[Descr],TmpS),!.

eval_descr(Ex,Descr,TmpS1,TmpS) :-
	make_descr(Ex,Descr,[],GenDescr),
	append(TmpS1,[GenDescr],TmpS).

make_descr([],[],Descr,Descr) :- !.
make_descr(Ex,OldDescr,Tmp,Descr) :-
	pop(Value1,Ex,Ex1),
	pop(Value2,OldDescr,OldDescr1),
	eval_entry(Value1,Value2,Value),
	append(Tmp,[Value],Tmp1),
	make_descr(Ex1,OldDescr1,Tmp1,Descr).

eval_entry(X,X,X) :- !.
eval_entry(_,_,nil).

remove(_,[],NewS,NewS) :- !.
remove(Ex,S,TmpS,NewS) :-
	pop(Descr,S,S1),
	remove_descr(Ex,Descr,TmpS,TmpS1),
	remove(Ex,S1,TmpS1,NewS).

remove_descr(Ex,Descr,TmpS,TmpS) :- unify(Ex,Descr),!.
remove_descr(_,Descr,TmpS1,TmpS) :- append(TmpS1,[Descr],TmpS).

unify([],[]).
unify([_|Rest1],[nil|Rest2]) :- unify(Rest1,Rest2).
unify([Value|Rest1],[Value|Rest2]) :- unify(Rest1,Rest2).

output_description(Attr,[X]) :- 
	nl,nl,
	output(Attr,X).

output([],[]).
output(Attr,X) :-
	pop(Feature,Attr,Attr1),
	pop(Value,X,X1),
	write_it(Feature,Value),
	output(Attr1,X1).

write_it(_,nil).
write_it(Feature,Value) :-
	write(Feature),
	write(' is '),
	write(Value),
	write('.'),nl.

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
