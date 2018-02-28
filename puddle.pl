%% -*- prolog -*-

:- module(puddle, []).

:- use_module(library(http/http_client)).

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
    store_fact(Gen, puddle_info(ProdVer, Url, Type, Puddle)).

:- add_fact_updater(puddle:update_puddle_facts).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% fact deducer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

deduce_puddle_facts(Gen) :-
    get_fact(puddle_info(ProdVer, Url, Type, New)),
    get_old_fact(puddle_info(ProdVer, Url, Type, Old)),
    New \== Old,
    store_fact(Gen, new_puddle(ProdVer, Url, Type, New, Old)).

deduce_puddle_facts(Gen) :-
    Gen \== 1,
    get_fact(puddle_info(ProdVer, Url, Type, New)),
    not(get_old_fact(puddle_info(ProdVer, Url, Type, _))),
    store_fact(Gen, new_puddle(ProdVer, Url, Type, New)).

:- add_fact_deducer(puddle:deduce_puddle_facts).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% fact solver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

puddle_solver(_) :-
    get_fact(new_puddle(ProdVer, _, Type, New, Old)),
    format(string(Text), "** new puddle ~w for ~w ~w (old was ~w)", [New, ProdVer, Type, Old]),
    notification(["puddle", ProdVer, "new"], Text).

puddle_solver(_) :-
    get_fact(new_puddle(ProdVer, _, Type, New)),
    format(string(Text), "** new puddle ~w for ~w ~w (first one)", [New, ProdVer, Type]),
    notification(["puddle", ProdVer, "new"], Text).

:- add_fact_solver(puddle:puddle_solver).

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

% puddle help
puddle_answer(List, _,
              ["Available commands:\n",
               bold("puddle"), ": display the list of available puddles.\n",
               bold("puddle <puddle>"), ": display the list of aliases for this puddle.\n",
               bold("puddle <puddle> <alias>"), ": display the real puddle name for this alias and its URL.\n",
               "Available notification:\n",
               bold("puddle <prodver> new")
              ]) :-
    member("puddle", List),
    member("help", List).

% puddle OSP10
puddle_answer(["puddle", ProdVer], _, Answer) :-
    findall(Type, get_fact(puddle_info(ProdVer, _, Type, _)), Types),
    string_join(", ", Types, TypesText),
    format(string(Answer), "~w ~w", [ProdVer, TypesText]).

% puddle OSP10 latest
puddle_answer(["puddle", ProdVer, Type], _, Answer) :-
    get_fact(puddle_info(ProdVer, Url, Type, Puddle)),
    format(string(Answer), "~w ~w is ~w ~w~w", [ProdVer, Type, Puddle, Url, Puddle]).

puddle_answer(["puddle", ProdVer, Type], _, Answer) :-
    format(string(Answer), "~w ~w does not exist", [ProdVer, Type]).

% puddle
puddle_answer(["puddle"], _, Answer) :-
    findall(ProdVer, get_fact(puddle_info(ProdVer, _, _, _)), ProdVers),
    sort(ProdVers, Prods),
    string_join(", ", Prods, ProdText),
    format(string(Answer), "available puddles: ~w", [ProdText]).

:- add_answerer(puddle:puddle_answer).

%% puddle.pl ends here
