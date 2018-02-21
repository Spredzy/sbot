%% -*- prolog -*-

:- begin_tests(test_utils).

:- use_module(utils).

test(dirbase) :-
    utils:dirbase(Dirname, Basename, "a/b/c/d/e"),
    assertion(Basename == "e"),
    assertion(Dirname == "a/b/c/d").

test(string_join) :-
    utils:string_join(" ", ["a", "b", "c"], Res),
    assertion(Res == "a b c").

test(cmd_fail) :-
    not(utils:cmd("fail", [])).

test(cmd_true) :-
    utils:cmd("true", [], []).

:- end_tests(test_utils).

%% test_utils.pl ends here