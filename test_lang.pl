%% -*- prolog -*-

:- use_module(lang).
:- use_module(discuss).

test_phrase(String) :-
    test_phrase(String, R),
    writeln(R).

test_phrase(String, Result) :-
    split_words(String, Words),
    writeln(Words),
    phrase(sentence(Result), Words).

:- begin_tests(test_lang).

test(basic) :- test_phrase("build the ansible package").
test(basic2) :- test_phrase("build ansible").

test(question) :- test_phrase("what is the status of osp12 job ?").
test(question2) :- test_phrase("what is the status of the osp12 job for dell?").

test(which) :- test_phrase("which partners are testing osp12?").

test(apply) :- test_phrase("apply pr 42 on ansible").

test(track) :- test_phrase("could you track pr 42 on the ansible package ?").

test(count) :- test_phrase("please could you count how many cards do we have?").
test(count2) :- test_phrase("how many cards?").
test(count3) :- test_phrase("count how many jobs on OSP12?").

:- end_tests(test_lang).

%% test_lang.pl ends here
