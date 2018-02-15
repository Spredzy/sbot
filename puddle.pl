%% -*- prolog -*-

:- module(puddle, []).

:- use_module(library(http/http_client)).

:- use_module(kb).
:- use_module(world).
:- use_module(discuss).
:- use_module(config).
:- use_module(utils).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% fact updater
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

update_puddle_facts(Gen) :-
    config(puddle, [Product, Version, Url]),
    get_puddle_fact(Version, Url, Type, Puddle),
    string_concat(Product, Version, ProdVer),
    update_fact(Gen, puddle_info(ProdVer, Url, Type, Puddle)).

:- add_fact_updater(puddle:update_puddle_facts).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% status predicates
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

get_puddle_fact(Version, Url, Type, Puddle) :-
    member(Type, ["latest", "passed_dci", "passed_phase1", "passed_phase2"]),
    format(string(Product), "RH7-RHOS-~w.0", [Version]),
    format(string(RepoUrl), "~w/~w/~w.repo", [Url, Type, Product]),
    http_get(RepoUrl, Repo, [status_code(Code)]),
    Code == 200,
    get_puddle_from_repo(Product, Repo, Puddle).

get_puddle_from_repo(Product, Repo, Puddle) :-
    split_string(Repo, "\n", "", Lines),
    member(Line, Lines),
    find_puddle(Product, Line, Puddle),
    !.

find_puddle(Product, Line, Puddle) :-
    split_string(Line, "=", "", ["baseurl", Url]),
    split_string(Url, "/", "", Parts),
    lookup_product(Product, Parts, Puddle).

lookup_product(Product, [Puddle, Product|_], Puddle) :-
    !.

lookup_product(Product, [_|Rest], Puddle) :-
    lookup_product(Product, Rest, Puddle).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Communication predicates
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% puddle OSP10
puddle_answer(Text, Nick, Answer) :-
    split_string(Text, " ", "", ["puddle", ProdVer]),
    findall(Type, get_fact(puddle_info(ProdVer, _, Type, _)), Types),
    string_join(", ", Types, TypesText),
    format(string(Answer), "~w: ~w ~w", [Nick, ProdVer, TypesText]).

% puddle OSP10 latest
puddle_answer(Text, Nick, Answer) :-
    split_string(Text, " ", "", ["puddle", ProdVer, Type]),
    get_fact(puddle_info(ProdVer, Url, Type, Puddle)),
    format(string(Answer), "~w: ~w ~w is ~w ~w~w", [Nick, ProdVer, Type, Puddle, Url, Puddle]).

puddle_answer(Text, Nick, Answer) :-
    split_string(Text, " ", "", ["puddle", ProdVer, Type]),
    format(string(Answer), "~w: ~w ~w does not exist", [Nick, ProdVer, Type]).

% puddle
puddle_answer(Text, Nick, Answer) :-
    split_string(Text, " ", "", ["puddle"]),
    findall(ProdVer, get_fact(puddle_info(ProdVer, _, _, _)), ProdVers),
    sort(ProdVers, Prods),
    string_join(", ", Prods, ProdText),
    format(string(Answer), "~w: available puddles: ~w", [Nick, ProdText]).

:- add_answerer(puddle:puddle_answer).

%% puddle.pl ends here
