%%%%%%%%%%%%%%%%%%%%%%%%%%%%% -*- Mode: Prolog -*- %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% para.pl --- 
%%% Author          : Anders Blehr
%%% Created On      : Tue Apr 21 13:53:37 1992
%%% Last Modified By: Anders Blehr
%%% Last Modified On: Sun May  3 11:30:22 1992
%%% RCS revision    : $Revision: 1.5 $ $Locker: blehr $
%%% Status          : Under development
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

paraphrase(Type,Rep) :-
	call_para(Type,Rep,Sent),
	write_sent(Sent).

call_para(rule,Rep1=>Rep2,Sent) :-
	call_para(rule,Rep2,Sent1),
	call_para(rule,Rep1,Sent2),
	append(Sent1,[if],TmpSent),
	append(TmpSent,Sent2,Sent),!.

call_para(Type,Rep,Sent) :-
	copy_term(Rep,Rep1),
	numbervars(Rep1,0,_),
	listify(Rep1,ListRep),
	call_sent(Type,Sent,ListRep),!.

call_sent(rule,Sent,List) :- sent(Sent,List,[]).
call_sent(noquery,Sent,List) :- 
	sent(Sent1,List,[]),
	extract_vars(Sent1,Sent2,[],Vars,[]),
	replace_vars(Sent2,Sent,Vars).

call_sent(query,Sent,List) :- 
	query_sent(Wh,Sent1,[],Vars,List,[]),
	replace_vars(Sent1,Sent2,Vars),
	compose_question(Wh,Sent2,Sent).

%%

query_sent(Wh,Sent,Vars1,Vars) --> [which,'(',X,')',':','(',Q,'(',X,')',&],
	query_sent(_,Sent,Vars1,Vars),[')'],{get_wh_pron(Q,Wh)},!.

query_sent(Wh,Sent,Vars1,Vars) --> [exists,'(',X,')',':','('],
	query_simple(Sent1),{append([(X,Sent1)],Vars1,Vars2)},[&],
	query_sent(Wh,Sent,Vars2,Vars),[')'],!.

query_sent(Wh,Sent,Vars1,Vars) --> 
	prep(P),['('],
	query_sent(Wh,Sent1,Vars1,Vars),[','],
	atom_term(A),[')'],{append(Sent1,[P,A],Sent)},!.

query_sent(is,[S,is|Rest],Vars,Vars) --> simple([S,is|Rest]),!.
query_sent(does,[S,V|Rest],Vars,Vars) --> simple([S,V|Rest]),!.

sent(Sent) --> [exists,'(',_,')',':','('],
	sent(Sent1),[')',&],
	sent(Sent2),
	{append(Sent1,[and],TmpSent),
	 append(TmpSent,Sent2,Sent)},!.

sent(Sent) --> [exists,'(',_,')',':','('],
	sent(Sent),[')'],!.

sent(Sent) -->
	simple(Sent1),[&],
	sent(Sent2),
	{append(Sent1,[and],TmpSent),
	 append(TmpSent,Sent2,Sent)},!.

sent(Sent) --> simple(Sent),!.

query_simple([Art,Noun]) --> noun_simple([_,is,Art,Noun]),!.
query_simple([Art,Noun|Rest]) --> prep_simple([_,is,Art,Noun|Rest]),!.

simple(Sent) --> noun_simple(Sent),!.
simple(Sent) --> adj_simple(Sent),!.
simple(Sent) --> iverb_simple(Sent),!.
simple(Sent) --> tverb_simple(Sent),!.
simple(Sent) --> prep_simple(Sent),!.

prep_simple(Sent) -->
	prep(P),['('],
	sent(Sent1),[','],
	atom_term(A),[')'],{append(Sent1,[P,A],Sent)},!.

prep_simple([A1,is,P,A2]) -->
	prep(P),['('],
	atom_term(A1),[','],
	atom_term(A2),[')'],!.

adj_simple([A,is,Adj]) -->
	adj(Adj),['('],
	atom_term(A),[')'].

noun_simple([A,is,Art,N]) -->
	noun(N),['('],{get_article(N,Art)},
	atom_term(A),[')'].

iverb_simple([A,IV]) -->
	iverb(IV1),['('],{present(IV1,IV)},
	atom_term(A),[')'].

tverb_simple([A1,TV,A2]) -->
	tverb(TV1),['('],{present(TV1,TV)},
	atom_term(A1),[','],
	atom_term(A2),[')'].

prep(P) --> [P],{prep(P)}.

adj(Adj) --> [Adj],{adj(Adj)}.

noun(N) --> [N],{noun(N)}.

iverb(IV) --> [IV],{intrans_verb(IV)}.

tverb(TV) --> [TV],{trans_verb(TV)}.

atom_term(A) --> [A],{atom_term(A)}.

%%

atom_term(A) :- name(A),!.
atom_term(A) :- abst_noun(A),!.
atom_term(A) :- time(A),!.
atom_term(A) :- var_term(A),!.

var_term(X) :- X=..['$VAR',_].

get_wh_pron(place,where).
get_wh_pron(W,who) :- member(W,[man,woman,person,child]),!.
get_wh_pron(W,when) :- member(W,[time,year]),!.

get_subject([Art,Noun],[Art,Noun|Sent],Sent) :- member(Art,[a,an]),!.
get_subject([S],[S|Sent],Sent) :- atom_term(S),!.

compose_question(does,Sent1,Sent) :-
	get_subject(Subj,Sent1,Sent2),
	pop(V1,Sent2,Sent3),
	infinitive(V,V1),
	append([does],Subj,Sent4),
	append(Sent4,[V],Sent5),
	append(Sent5,Sent3,Sent6),
	append(Sent6,['?'],Sent),!.

compose_question(is,Sent1,Sent) :-
	get_subject(Subj,Sent1,Sent2),
	pop(is,Sent2,Sent3),
	append([is],Subj,Sent4),
	append(Sent4,Sent3,Sent5),
	append(Sent5,['?'],Sent),!.

compose_question(who,Sent1,Sent) :-
	pop(S,Sent1,Sent2),
	var_term(S),
	append([who],Sent2,Sent3),
	append(Sent3,['?'],Sent),!.

compose_question(who,Sent1,Sent) :-
	get_subject(Subj,Sent1,Sent2),
	pop(V1,Sent2,Sent3),
	get_subject(_,Sent3,Sent4),
	infinitive(V,V1),
	append([whom,does],Subj,Sent5),
	append(Sent5,[V],Sent6),
	append(Sent6,Sent4,Sent7),
	append(Sent7,['?'],Sent),!.

compose_question(Wh_pron,[S,is,Adj|_],Sent) :-
	member(Wh_pron,[when,where]),
	unify(Sent,[Wh_pron,is,S,Adj,'?']),!.

compose_question(Wh_pron,Sent1,Sent) :-
	member(Wh_pron,[when,where]),
	get_subject(Subj,Sent1,Sent2),
	pop(V1,Sent2,Sent3),
	infinitive(V,V1),
	append([Wh_pron,does],Subj,Sent4),
	append(Sent4,[V],Sent5),
	append(Sent6,[in|_],Sent3),
	append(Sent5,Sent6,Sent7),
	append(Sent7,['?'],Sent),!.

replace_vars([],[],_).
replace_vars([VarS|Rest1],Sent,Vars) :-
	var_term(VarS),
	find_var(VarS,ListS,Vars),
	\+ (ListS=[nil|_]),
	replace_vars(Rest1,Rest,Vars),
	append(ListS,Rest,Sent),!.

replace_vars([W|Rest1],[W|Rest],Vars) :- replace_vars(Rest1,Rest,Vars),!.

extract_vars(Sent1,Sent,Vars1,Vars,Visited1) :-
	append([S,is,Art,N|SRest],[and|Rest],Sent1),
	var_term(S),
	\+ member(S,Visited1),
	member(Art,[a,an]),
	append([S],Visited1,Visited),
	append([(S,[Art,N|SRest])],Vars1,Vars2),
	extract_vars(Rest,Sent,Vars2,Vars,Visited),!.

extract_vars(Sent1,Sent,Vars1,Vars,Visited) :-
	append([S,is,Adj],[and|Rest],Sent1),
	member(S,Visited),
	adj(Adj),
	get_article(Adj,Art),
	pop((S,[_|SRest]),Vars1,Vars2),
	append([(S,[Art,Adj|SRest])],Vars2,Vars3),
	extract_vars(Rest,Sent,Vars3,Vars,Visited).

extract_vars(Sent1,Sent,Vars1,Vars,Visited) :-
	append(Sent2,[and|Rest],Sent1),
	extract_vars(Rest,Sent3,Vars1,Vars,Visited),
	append(Sent2,[and],TmpSent),
	append(TmpSent,Sent3,Sent),!.

extract_vars(Sent,Sent,Vars,Vars,_).

find_var(_,(nil,nil),[]).
find_var(VarS,S,Vars) :- pop((VarS,S),Vars,_),!.
find_var(VarS,S,Vars) :-
	pop(_,Vars,Vars1),
	find_var(VarS,S,Vars1),!.

write_sent([]).
write_sent(Sent) :- 
	pop(W,Sent,Sent1),
	write(W),
	write(' '),
	write_sent(Sent1).
