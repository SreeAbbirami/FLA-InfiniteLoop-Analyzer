%%% README %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%% To run the tests from the project root:
%%%   `make test` or `swipl -g "consult('src/tests.pl'), run_tests" -t halt`
%%% Then, run the following command to execute all tests: `run_tests.`.
%%%
%%% Expected results:
%%%   - All tests must pass without generating any errors.
%%%   - The plunit report should indicate this line:
%%%     All 64 (+12 sub-tests) tests passed in [Time] seconds ([CPU] cpu)
%%%
%%% Why these tests?
%%%   - Each group of tests verifies a specific predicate or behavior,
%%%     including both edge cases and general cases.
%%%
%%% IMPORTANT:
%%%   - For these tests to function correctly, the `examples.zip` folder must be unzipped.
%%%

:- use_module(library(plunit)).  % Library for testing
:- ensure_loaded("analyzer.pl"). % Load the file to test

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%% Tests for basic Predicate
%%%%% - Parent
%%%%% - Children
%%%%% - Ancestor
%%%%% - Print_Tree

%%% README %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%% For each of the main predicates defined above, we test all of them using unit tests.
%%% All edge cases and general cases are tested. For example, if `my_predicate` is defined as
%%% `my_predicate(ID_A, ID_B)` but can be run in both directions, we will test both scenarios
%%% (when ID_A is instantiated and ID_B is not, and vice versa).
%%%
%%% Remarks:
%%%   - For the Ancestor predicate, the helper predicates are not directly tested
%%%     but are implicitly verified since we test every possible case in Ancestor, and this predicate
%%%     calls these helper predicates.
%%%   - For the Print_Tree predicate, some of the helper predicates are tested here because this
%%%     predicate is more complex. For example, `print_node` is tested as it is independent,
%%%     whereas print_children is not, as it recursively calls `print_node` for all children,
%%%     making it less useful to test separately if `print_node` works correctly.
%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Tests for parent(+Cid, -Pid) predicate %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

:- begin_tests(parent, 
    [setup(load_file('examples/basic_predicates/general_code.pl')),
     cleanup(retract_all_nodes)]).

test(parent_direct_true, [forall(member([Cid, Pid], [[18, 17], [8, 7], [52, 51]]))]) :-
    parent(Cid, Pid).

test(parent_via_list_true, [forall(member([Cid, Pid], [[27, 1], [23, 22], [37, 35]]))]) :-
    parent(Cid, Pid).

test(parent_with_Pid_unbound_1, [true(X == 38)]) :- parent(40, X).
test(parent_with_Pid_unbound_2, [true(X == 0)]) :- parent(45, X).

test(parent_false_cases, [forall(member([Cid, Pid], [[25, 26], [27, 17]])), fail]) :-
    parent(Cid, Pid).

test(parent_Cid_is_root, [fail]) :- parent(0, _).
test(parent_invalid_Cid, [forall(member(Cid, [1000, -1])), fail]) :- parent(Cid, _).

:- end_tests(parent).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Tests for children(+Pid, -ChildrenIds) predicate %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

:- begin_tests(children, 
    [setup(load_file('examples/basic_predicates/general_code.pl')),
     cleanup(retract_all_nodes)]).

test(children_single_true) :- children(83, [84]).
test(children_multiple_true) :- children(79, [80,82,83]).
test(children_empty, [true(Children == [])]) :- children(112, Children).
test(children_one_children, [true(Children == [104])]) :- children(103, Children).
test(children_three_children, [true(Children == [4,5,7])]) :- children(3, Children).
test(children_lot_of_children, [true(Children == [2,12,27,34,35,44])]) :- children(1, Children).
test(children_invalid_Pid, [forall(member(Pid, [1000, -1])), fail]) :- children(Pid, _).

:- end_tests(children).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Tests for ancestor(?ChildId, ?AncestorId) predicate %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

:- begin_tests(ancestor, 
    [setup(load_file('examples/basic_predicates/general_code.pl')),
     cleanup(retract_all_nodes)]).

test(ancestor_direct, [forall(member([Child, Parent], [[1, 0], [6,5], [17,13]]))]) :-
    ancestor(Child, Parent).

test(ancestor_indirect, [forall(member([Child, Ancestor], [[7,0], [14,12], [54, 46]]))]) :-
    ancestor(Child, Ancestor).

test(ancestor_direct_invalid, [fail]) :-ancestor(41,42).
test(ancestor_indirect_invalid, [fail]) :- ancestor(35,42).
test(ancestor_all_of_7, set(X == [0,1,2,3])) :- ancestor(7, X).
test(ancestor_all_of_11, set(X == [96,78,0])) :- ancestor(101, X).
test(ancestor_all_of_1, set(X == [0])) :- ancestor(1, X).
test(descendant_all_of_7, set(X == [8])) :- ancestor(X, 7).
test(descendant_of_10_empty, set(X == [])) :- ancestor(X, 10).

test(descendant_all_from_root, [true(SortedX == SortedExpectedDescendants)]) :-
    numlist(1, 112, ExpectedDescendants),
    findall(Descendant, ancestor(Descendant, 0), X),
    sort(X, SortedX),
    sort(ExpectedDescendants, SortedExpectedDescendants).

test(descendant_all_of_12, [true(SortedX == SortedExpectedDescendants)]) :-
    numlist(13, 26, ExpectedDescendants),
    findall(Descendant, ancestor(Descendant, 12), X),
    sort(X, SortedX),
    sort(ExpectedDescendants, SortedExpectedDescendants).

test(ancestor_invalid_Pid, [forall(member(Pid, [1000, -1])), fail]) :- ancestor(_, Pid).

:- end_tests(ancestor).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Tests for print_tree/0 predicate %%%
%%% and helper predicates            %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Tests for indent(+IndentLevel) %
:- begin_tests(indent).

test(indent_positive_level) :-
    with_output_to(string(Output), indent(2)),
    assertion(Output == "        ").

test(indent_zero_level) :-
    with_output_to(string(Output), indent(0)),
    assertion(Output == "").

test(indent_negative_level, [fail]) :- indent(-1).

test(indent_non_integer_level, [fail]) :- indent(1.5).

:- end_tests(indent).

% Tests for print_node(+Type, +NodeId, +Value, +IndentLevel) %
:- begin_tests(print_node).

test(print_node_with_bad_indentation, [fail]) :- print_node(leaf, 1, 42, -1).

test(print_node_with_indentation) :-
    with_output_to(string(Output), print_node(leaf, 1, 42, 2)),
    assertion(Output == "        Node 1: Type=leaf, Value=42\n").

test(print_node_no_indentation) :-
    with_output_to(string(Output), print_node(leaf, 1, 42, 0)),
    assertion(Output == "Node 1: Type=leaf, Value=42\n").

test(print_node_different_type_and_value) :-
    with_output_to(string(Output), print_node(branch, 2, 100, 1)),
    assertion(Output == "    Node 2: Type=branch, Value=100\n").

:- end_tests(print_node).

% Tests for print_tree/0, print_tree(+NodeId) and print_tree(+NodeId, +Verbose) %
:- begin_tests(print_tree,
    [setup(load_file('examples/basic_predicates/general_code.pl')),
     cleanup(retract_all_nodes)]).

test(print_tree_full_tree_verbose_on_tests) :-
    with_output_to(string(Output1), print_tree),
    with_output_to(string(Output2), print_tree(true)),
    with_output_to(string(Output3), print_tree(0, true)),
    read_file_to_string('examples/basic_predicates/tree_print/full_tree_verbose_on.txt', ExpectedOutput, []),
    assertion(Output1 == ExpectedOutput),
    assertion(Output2 == ExpectedOutput),
    assertion(Output3 == ExpectedOutput).

test(print_tree_full_tree_verbose_off_tests) :-
    with_output_to(string(Output1), print_tree(false)),
    with_output_to(string(Output2), print_tree(0, false)),
    read_file_to_string('examples/basic_predicates/tree_print/full_tree_verbose_off.txt', ExpectedOutput, []),
    assertion(Output1 == ExpectedOutput),
    assertion(Output2 == ExpectedOutput).

test(print_tree_root12_verbose_on_tests) :-
    with_output_to(string(Output1), print_tree(12)),
    with_output_to(string(Output2), print_tree(12, true)),
    read_file_to_string('examples/basic_predicates/tree_print/tree_root12_verbose_on.txt', ExpectedOutput, []),
    assertion(Output1 == ExpectedOutput),
    assertion(Output2 == ExpectedOutput).

test(print_tree_root12_verbose_off_tests) :-
    with_output_to(string(Output), print_tree(12, false)),
    read_file_to_string('examples/basic_predicates/tree_print/tree_root12_verbose_off.txt', ExpectedOutput, []),
    assertion(Output == ExpectedOutput).

:- end_tests(print_tree).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%% Tests for pattern recognition %%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% README %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%% These 13 tests follow the same logic. Each test verifies two predicates:
%%%   - `has_[pattern]`, which checks if the pattern is present.
%%%   - `get_[pattern]`, which retrieves relevant elements (e.g., function IDs, names).
%%%
%%% Each test is performed on two files (`yes.pl` and `no.pl`), located in a folder named after the pattern.
%%%   - The `yes.pl` file contains cases where the pattern is present.
%%%   - The `no.pl` file contains cases where the pattern is absent.
%%%
%%% The test structure follows a standardized approach:
%%%   - The `yes_tests` case loads `yes.pl`, verifies the presence of the pattern, and ensures `get_[pattern]` returns an empty list.
%%%   - The `no_tests` case loads `no.pl`, verifies the absence of the pattern, and checks that `get_[pattern]` returns the expected elements.
%%%   - `retract_all_nodes` is called after each test to reset the state.
%%%
%%% Example:
%%%   - `examples/return_last_statement/yes.pl` contains functions where the last statement is a return.
%%%   - `examples/return_last_statement/no.pl` contains functions where the last statement is not a return.
%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Tests for Detecting Functions %%%
%%% with Return as Last Statement %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

:- begin_tests(return_last_statement).

test(yes_tests) :-
    load_file('examples/return_last_statement/yes.pl'),
    has_all_functions_have_return_as_last_statement,
    get_functions_without_return_as_last_statement(EmptyList),
    EmptyList == [],
    retract_all_nodes.

test(no_tests) :-
    load_file('examples/return_last_statement/no.pl'),
    \+ has_all_functions_have_return_as_last_statement,
    get_functions_without_return_as_last_statement(FunctionsWithoutReturn),
    FunctionsWithoutReturn == [21, 41, 57, 79],
    retract_all_nodes.

:- end_tests(return_last_statement).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Tests for Detecting Loop %%%
%%% with Unused Variables    %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

:- begin_tests(unused_loop_vars).

test(yes_tests) :-
    load_file('examples/unused_loop_vars/yes.pl'),
    \+ has_all_loop_have_used_vars,
    get_loop_with_unused_vars(LoopsWithUnusedVars),
    LoopsWithUnusedVars == [8-["i"],
                            48-["key"],
                            85-["j","k"],
                            162-["j"]],
    retract_all_nodes.

test(no_tests) :-
    load_file('examples/unused_loop_vars/no.pl'),
    has_all_loop_have_used_vars,
    get_loop_with_unused_vars(LoopsWithUnusedVars),
    LoopsWithUnusedVars == [],
    retract_all_nodes.

:- end_tests(unused_loop_vars).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Tests for Detecting the %%%
%%% Accumulator Pattern     %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

:- begin_tests(accumulator_patterns).

test(yes_tests) :-
    load_file('examples/accumulator_patterns/yes.pl'),
    has_accumulator_patterns,
    get_functions_with_accumulator(Results),
    Results == [[1, "sum_list", "total"],
                [31, "concatenate_strings", "result"],
                [61, "multiply_list", "product"],
                [91, "count_occurrences", "count"],
                [128, "build_dict", "result"]],
    retract_all_nodes.

test(no_tests) :-
    load_file('examples/accumulator_patterns/no.pl'),
    \+ has_accumulator_patterns,
    get_functions_with_accumulator(Results),
    Results == [],
    retract_all_nodes.

:- end_tests(accumulator_patterns).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Tests for Detecting Class Constructor %%%
%%% with Empty __init__() Method          %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

:- begin_tests(constructor_empty).

test(yes_tests) :-
    load_file('examples/constructor_empty/yes.pl'),
    has_empty_init,
    get_classes_with_empty_init(ClassesWithEmptyInit),
    ClassesWithEmptyInit == ["EmptyClass"-1,
                             "AnotherEmptyClass"-12,
                             "PartiallyEmptyClass"-29,
                             "InnerClass"-53],
    retract_all_nodes.

test(no_tests) :-
    load_file('examples/constructor_empty/no.pl'),
    \+ has_empty_init,
    get_classes_with_empty_init(ClassesWithEmptyInit),
    ClassesWithEmptyInit == [],
    retract_all_nodes.

:- end_tests(constructor_empty).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Tests for Detecting Class Constructor      %%%
%%% with Return statement in __init__() Method %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

:- begin_tests(constructor_return).

test(yes_tests) :-
    load_file('examples/constructor_return/yes.pl'),
    has_init_returns_object,
    get_classes_with_init_return_object(ClassesWithInitReturn),
    ClassesWithInitReturn == [class("BadClass1", ["self"]),
                              class("BadClass2", ["self", "BadClass2"]),
                              class("BadClass3", ["BadClass3"]),
                              class("BadClass4", ["self"])],
    retract_all_nodes.

test(no_tests) :-
    load_file('examples/constructor_return/no.pl'),
    \+ has_init_returns_object,
    get_classes_with_init_return_object(ClassesWithInitReturn),
    ClassesWithInitReturn == [],
    retract_all_nodes.

:- end_tests(constructor_return).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Tests for Detecting Functions %%%
%%% that Earase their Arguments   %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

:- begin_tests(parameters_reassignement).

test(yes_tests) :-
    load_file('examples/parameters_reassignement/yes.pl'),
    has_erase_args,
    get_functions_that_erase_args(FunctionsWithReassignedParams),
    FunctionsWithReassignedParams == ["bad_function1"-1-["x"],
                                     "bad_function2"-26-["values"],
                                     "bad_function3"-61-["c"],
                                     "bad_function4"-95-["factor"],
                                     "bad_function5"-138-["x", "y"]],
    retract_all_nodes.

test(no_tests) :-
    load_file('examples/parameters_reassignement/no.pl'),
    \+ has_erase_args,
    get_functions_that_erase_args(FunctionsWithReassignedParams),
    FunctionsWithReassignedParams == [],
    retract_all_nodes.

:- end_tests(parameters_reassignement).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Tests for Detecting Incremented For Loops                %%%
%%% (where the Loop Variable is Incremented inside the loop) %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

:- begin_tests(increment_in_forloop).

test(yes_tests) :-
    load_file('examples/increment_in_forloop/yes.pl'),
    has_incr_in_for_loops,
    get_loop_with_var_increment(LoopsWithManualIncrement),
    LoopsWithManualIncrement == [2-"i",
                                 25-"idx",
                                 58-"j",
                                 89-"i",
                                 128-"i"],
    retract_all_nodes.

test(no_tests) :-
    load_file('examples/increment_in_forloop/no.pl'),
    \+ has_incr_in_for_loops,
    get_loop_with_var_increment(LoopsWithManualIncrement),
    LoopsWithManualIncrement == [],
    retract_all_nodes.

:- end_tests(increment_in_forloop).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Tests for Detecting Functions with an          %%%
%%% Early Return statement (Return inside a Loop)  %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

:- begin_tests(early_return).

test(yes_tests) :-
    load_file('examples/early_return/yes.pl'),
    has_early_return,
    get_functions_with_early_return_misconception(FunctionsWithEarlyReturn),
    FunctionsWithEarlyReturn == ["bad_function1"-1,
                                "bad_function2"-21,
                                "bad_nested_function"-50,
                                "bad_while_function"-83,
                                "bad_complex_loop"-111],
    retract_all_nodes.

test(no_tests) :-
    load_file('examples/early_return/no.pl'),
    \+ has_early_return,
    get_functions_with_early_return_misconception(FunctionsWithEarlyReturn),
    FunctionsWithEarlyReturn == [],
    retract_all_nodes.

:- end_tests(early_return).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Tests for Detecting Functions %%%
%%% with Too Much Nested Blocks   %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

:- begin_tests(too_much_indent).

test(yes_tests) :-
    load_file('examples/too_much_indent/yes.pl'),
    has_too_much_indent,
    get_functions_with_too_much_indent(FunctionsWithTooMuchIndent),
    FunctionsWithTooMuchIndent == ["deeply_nested_function"-1-4,
                                  "another_nested_function"-42-4,
                                  "nested_conditions"-80-4,
                                  "complex_nested_loops"-123-3],
    retract_all_nodes.

test(no_tests) :-
    load_file('examples/too_much_indent/no.pl'),
    \+ has_too_much_indent,
    get_functions_with_too_much_indent(FunctionsWithTooMuchIndent),
    FunctionsWithTooMuchIndent == [],
    retract_all_nodes.

:- end_tests(too_much_indent).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Tests for Detecting Functions   %%%
%%% with Print Statement instead of %%%
%%% Return Statement (as last one)  %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

:- begin_tests(print_instead_return).

test(yes_tests) :-
    load_file('examples/print_instead_return/yes.pl'),
    has_print_instead_return,
    get_functions_with_print_misconception(FunctionsWithPrintReturnMisconception),
    FunctionsWithPrintReturnMisconception == ["calculate_sum"-7,
                                             "process_data"-35,
                                             "process_data_if_else"-70,
                                             "process_data_try_except"-105,
                                             "complex_function"-139,
                                             "main"-202],
    retract_all_nodes.

test(no_tests) :-
    load_file('examples/print_instead_return/no.pl'),
    \+ has_print_instead_return,
    get_functions_with_print_misconception(FunctionsWithPrintReturnMisconception),
    FunctionsWithPrintReturnMisconception == [],
    retract_all_nodes.

:- end_tests(print_instead_return).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Tests for Detecting Infinite Loop %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

:- begin_tests(infinite_loop).

test(yes_tests) :-
    load_file('examples/infinite_loop/yes.pl'),
    has_infinite_loops,
    get_infinite_loops(InfiniteLoops),
    InfiniteLoops == [26, 69, 113, 134],
    retract_all_nodes.

test(no_tests) :-
    load_file('examples/infinite_loop/no.pl'),
    \+ has_infinite_loops,
    get_infinite_loops(InfiniteLoops),
    InfiniteLoops == [],
    retract_all_nodes.

:- end_tests(infinite_loop).


%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Tests for Detecting %%%
%%% Too Long Functions  %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

:- begin_tests(too_long_function).

test(yes_tests) :-
    load_file('examples/too_long_function/yes.pl'),
    has_too_long_functions,
    get_too_long_functions(TooLongFunctions),
    TooLongFunctions == ["too_long_function"-1-21],
    retract_all_nodes.

test(no_tests) :-
    load_file('examples/too_long_function/no.pl'),
    \+ has_too_long_functions,
    get_too_long_functions(TooLongFunctions),
    TooLongFunctions == [],
    retract_all_nodes.

:- end_tests(too_long_function).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Tests for Detecting Functions %%%
%%% with Too Much Parameters      %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

:- begin_tests(too_many_parameters).

test(yes_tests) :-
    load_file('examples/too_many_parameters/yes.pl'),
    has_too_many_parameters,
    get_functions_with_too_many_parameters(FunctionsWithTooManyParameters),
    FunctionsWithTooManyParameters == ["five_params"-1-6,
                                      "too_many_parameters"-21-7,
                                      "process_data"-72-8,
                                      "calculate_stats"-129-9],
    retract_all_nodes.

test(no_tests) :-
    load_file('examples/too_many_parameters/no.pl'),
    \+ has_too_many_parameters,
    get_functions_with_too_many_parameters(FunctionsWithTooManyParameters),
    FunctionsWithTooManyParameters == [],
    retract_all_nodes.

:- end_tests(too_many_parameters).