%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Structure of a node :                             %%%
%%%     node(NodeType, NodeId, ChildNodes, Values).   %%%
%%%     ChildNodes = [childlabel:Id | ChildNodesTail] %%%
%%%     Values     = [valuesLabel:value | ValuesTail] %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% README %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%% To load this file from the project root:
%%%   `swipl src/analyzer.pl [your_filename.pl]`
%%% The option [your_filename.pl] is optional and allows you to directly load
%%% the file you want to analyze.
%%% You can also manually change the file used for analysis (without reloading
%%% the entire `analyzer.pl` file) with the command: `load_file(+FileName).`.
%%%
%%% Remark:
%%% - For all the commands above, you need to be at the root of the project,
%%%   and the path to your_filename.pl must be relative to the project root.
%%%
%%% To run the tests, refer to the README inside the `tests.pl` file or use `make test`.
%%%
%%% There is an example in `examples/demo/all_good_practice.pl` that shows a parsed code
%%% that uses good practices and an example in `examples/demo/lot_of_bad_patterns.pl`
%%% that shows the opposite.
%%%

% To avoid warnings at compilation.
:- dynamic node/4, for1/1, functiondef1/1, while1/1, classdef1/1.

% Initialisation: ensures that the main/0 predicate is executed automatically when the file is consulted.
:- initialization(main).

% main/0
%
% Acts as the entry point of the program.
% - Retrieves command-line arguments using current_prolog_flag(argv, Argv).
% - If an argument is provided, calls load_file/1 with the file name.
% - If no argument is provided, does nothing (true).
%
main :-
    current_prolog_flag(argv, Argv),
    (   Argv = [FileName | _]
        ->  load_file(FileName)
        ;   true
    ).

% load_file/1
%
% Loads the input file and initializes dynamic predicates.
% - FileName: The name of the file to load (must have a .pl extension).
% - Stops execution with an error message if the file is invalid.
%
load_file(FileName) :-
    (   file_name_extension(_, pl, FileName)
    ->  format('Loading file: ~w~n', [FileName]),
        retract_all_nodes,
        consult(FileName),
        declare_dynamic_predicates,
        generate_aux_predicates
    ;   format('Error: The file ~w must have a .pl extension.~n', [FileName]),
        halt(1)
    ).

% declare_dynamic_predicates/0
%
% Declares dynamic predicates for all node types in the loaded file.
% - Collects all unique node types using `setof/3`.
% - For each type, declares a dynamic predicate named `<Type>1/1`.
% - Used to dynamically manage predicates based on node types.
%
declare_dynamic_predicates :-
    setof(Type, Pid^Children^Value^node(Type, Pid, Children, Value), UniqueTypes),
    forall(member(Type, UniqueTypes), (
        atom_concat(Type, '1', PredicateName),
        dynamic(PredicateName/1)
    )).

% generate_aux_predicates/0
%
% Generates auxiliary predicates for all nodes in the loaded file.
% - Collects all unique pairs of node types and their IDs using `setof/3`.
% - For each pair, generates a predicate `<Type>1(Pid)` that succeeds if `node(Type, Pid, _, _)` is true.
% - Retracts any existing predicates to avoid duplicates.
% - Used to simplify queries involving node types and IDs.
%
generate_aux_predicates :-
    setof(Type-Pid, Children^Value^node(Type, Pid, Children, Value), UniquePairs),
    forall(member(Type-Pid, UniquePairs), (
        atom_concat(Type, '1', PredicateName),
        Predicate =.. [PredicateName, Pid],
        retractall(Predicate),
        assertz((Predicate :- node(Type, Pid, _, _)))
    )).

% retract_all_nodes/0
%
% Retracts all node/4 facts from the database.
% - Used for cleanup after tests.
%
retract_all_nodes :-
    retractall(node(_, _, _, _)).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Step 1 - Navigating the hierarchy %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%
%%% Parent Predicate %%%
%%%%%%%%%%%%%%%%%%%%%%%%

% parent(+Cid, -Pid)
%
% Finds the parent Pid of a given child Cid in a tree structure.
% - Cid must be instantiated and not equal to 0 (root node).
% - Pid is the parent node ID where Cid is a child.
% - Fails if Cid has no parent or if Cid is invalid.
%
parent(Cid, Pid) :-
    nonvar(Cid),
    Cid \= 0,
    node(_, Pid, Children, _),
    member(_:Value, Children),
    ( is_list(Value)
        ->  member(Cid, Value)
        ;   Cid = Value
    ), !.

%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Children Predicate %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%

% children(+Pid, -ChildrenIds)
%
% Returns the list of child IDs (ChildrenIds) for a given parent ID (Pid).
% - Pid must be instantiated.
% - ChildrenIds is unified with a list of child IDs.
% - Fails if Pid has no children or is invalid.
%
children(Pid, ChildrenIds) :-
    nonvar(Pid),
    node(_, Pid, Children, _),
    findall(ChildId, extract_child_id(Children, ChildId), ChildrenIds).

% extract_child_id(+Children, -ChildId)
%
% Extracts a child ID (ChildId) from a Children list.
% - Children is a list of pairs `Label:Value`.
% - ChildId is unified with a child ID from the list.
%
extract_child_id(Children, ChildId) :-
    member(_:Value, Children),
    extract_id_from_value(Value, ChildId).

% extract_id_from_value(+Value, -ChildId)
%
% Extracts a child ID (ChildId) from a Value, which can be a list or a single value.
% - Value is either a list of IDs or a single ID.
% - ChildId is unified with the extracted ID.
%
extract_id_from_value(Value, ChildId) :-
    ( is_list(Value)
        ->  member(ChildId, Value)
        ;   ChildId = Value
    ).


%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Ancestor Predicate %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%

% ancestor(+ChildId, +AncestorId)
% ancestor(+ChildId, -AncestorId)
% ancestor(-ChildId, +AncestorId)
%
% Determines ancestor relationships.
% - If both args are instantiated, checks if AncestorId is an ancestor of ChildId.
% - If only ChildId is instantiated, finds all ancestors of ChildId.
% - If only AncestorId is instantiated, finds all descendants of AncestorId.
% - Throws an error if neither is instantiated.
%
ancestor(ChildId, AncestorId) :-
    ( nonvar(ChildId), nonvar(AncestorId)
        ->  once(ancestor_up(ChildId, AncestorId)) % Once() to return true after finding the first child
        ;   nonvar(ChildId)
        ->  ancestor_up(ChildId, AncestorId)
        ;   nonvar(AncestorId)
        ->  descendant_down(AncestorId, ChildId)
        ;   throw(error(instantiation_error, ancestor/2)) % Throw error
    ).

% ancestor_up(+Child, -Ancestor)
%
% Finds ancestors of Child.
% - Direct: parent(+Child, -Ancestor).
% - Indirect: recursively finds ancestors of the parent.
%
ancestor_up(Child, Ancestor) :-
    parent(Child, Ancestor).
ancestor_up(Child, Ancestor) :-
    parent(Child, Parent),
    ancestor_up(Parent, Ancestor).

% descendant_down(+Ancestor, -Descendant)
%
% Finds descendants of Ancestor.
% - Direct: member of children(+Ancestor, -Descendant).
% - Indirect: recursively finds descendants of children.
%
descendant_down(Ancestor, Descendant) :-
    children(Ancestor, Children),
    member(Descendant, Children).
descendant_down(Ancestor, Descendant) :-
    children(Ancestor, Children),
    member(Child, Children),
    descendant_down(Child, Descendant).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Print_tree Predicate %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% print_tree/0
% print_tree(+Verbose)
%
% Prints the entire tree starting from the root node (NodeId = 0).
% - Verbose: If false, ignored nodes (store, load, null,...) are skipped.
%
print_tree :-
    print_tree(true).

print_tree(Verbose) :-
    ( Verbose == false ; Verbose == true)
    ->  print_tree(0, Verbose)
    ;   print_tree(Verbose, true). % Verbose = Node here (tricky)

% print_tree(+NodeId, +Verbose)
%
% Prints the tree structure starting from the given NodeId.
% - NodeId: The starting node ID.
% - Verbose: If false, ignored nodes are not printed.
%
print_tree(NodeId, Verbose) :-
    nonvar(NodeId), nonvar(Verbose),
    print_tree(NodeId, 0, Verbose).

% print_tree(+NodeId, +IndentLevel, +Verbose)
%
% Recursively prints the tree structure with indentation.
% - NodeId: The current node to print.
% - IndentLevel: The current level of indentation.
% - Verbose: If false, ignored nodes are skipped.
%
print_tree(NodeId, IndentLevel, Verbose) :-
    node(Type, NodeId, _, Value),
    ( ignore(NodeId), Verbose = false
        ->  true
        ;   print_node(Type, NodeId, Value, IndentLevel)
    ),
    children(NodeId, ChildrenIds),
    NewIndentLevel is IndentLevel + 1,
    print_children(ChildrenIds, NewIndentLevel, Verbose),
    !.

% print_node(+Type, +NodeId, +Value, +IndentLevel)
%
% Prints the details of a single node with proper indentation.
% - Type: The type of the node.
% - NodeId: The ID of the node.
% - Value: The value associated with the node.
% - IndentLevel: The level of indentation for formatting.
%
print_node(Type, NodeId, Value, IndentLevel) :-
    indent(IndentLevel),
    format('Node ~w: Type=~w, Value=~w~n', [NodeId, Type, Value]).

% print_children(+ChildrenIds, +IndentLevel, +Verbose)
%
% Recursively prints all children of a node.
% - ChildrenIds: The list of child node IDs.
% - IndentLevel: The current level of indentation.
% - Verbose: If false, ignored nodes are skipped.
%
print_children([], _, _).
print_children([ChildId|Tail], IndentLevel, Verbose) :-
    print_tree(ChildId, IndentLevel, Verbose),
    print_children(Tail, IndentLevel, Verbose).

% indent(+IndentLevel)
%
% Prints spaces for indentation based on the IndentLevel.
% - IndentLevel: The number of levels to indent.
%
indent(IndentLevel) :-
    IndentLevel > 0,
    integer(IndentLevel),
    Spaces is IndentLevel * 4,
    format('~*c', [Spaces, 32]),
    !.
indent(0).

% ignore(+NodeId)
%
% Checks if a node should be ignored based on its type.
% - NodeId: The ID of the node to check.
% - Succeeds if the node's type is in the list of ignored types.
%
ignore(NodeId) :-
    nonvar(NodeId),
    node(Type, NodeId, _, _),
    ignore_type(Type).

% ignore_type(+Type)
%
% Defines node types to ignore.
%
ignore_type(store).
ignore_type(load).
ignore_type(null).
ignore_type(add).
ignore_type(eq).
ignore_type(mod).
ignore_type(lt).
ignore_type(mult).
ignore_type(div).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Step 2 - Simple Syntactic Queries %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Checking Returns Statement %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% has_all_functions_have_return_as_last_statement/0
%
% Verifies that all defined functions end with a return statement as their last node.
% - Succeeds (returns true) if all functions have return statements as their final body element.
% - Fails (returns false) if any function lacks a final return statement.
%
has_all_functions_have_return_as_last_statement :-
    ( current_predicate(functiondef1/1) % True if functiondef1/1 is dynamically declared
        ->  findall(FunctionId, functiondef1(FunctionId), FunctionIds),
            maplist(has_return_as_last_statement, FunctionIds)
        ;   true
    ), !.

% display_functions_without_return_as_last_statement/0
%
% Checks if all functions end with a return statement and prints details for those that do not.
% Uses `functiondef1/1` to retrieve function IDs and `get_functions_without_return_as_last_statement/1`
% to verify return statements and got informations about that.
%
display_functions_without_return_as_last_statement :-
    format('----------------------------------------------~n'),
    ( current_predicate(functiondef1/1)
        ->  get_functions_without_return_as_last_statement(FunctionsWithoutReturn),
        ( FunctionsWithoutReturn = []
            ->  format('All functions have a `return` as their last statement.~n')
            ;   format('Some functions are missing a `return` as last statement.~n'),
                forall(member(FunctionId, FunctionsWithoutReturn), (
                    node(functiondef, FunctionId, _, Attrs),
                    ( member(name:Name, Attrs)
                        ->  format('  - Function "~w" (ID ~w)~n', [Name, FunctionId])
                        ;   format('  - Function "unnamed" (ID ~w)~n', [FunctionId])
                    )
                )
            )
        )
        ; format('No function in your file.~n')
    ),
    format('----------------------------------------------~n').

% get_functions_without_return_as_last_statement(-FunctionsWithoutReturn)
%
% Retrieves all functions that do not have a `return` statement as their last statement.
% - Returns a list of `FunctionId` for violating functions.
%   - `FunctionId`: The unique ID of the function.
% - Returns an empty list if all functions have a `return` statement as their last statement.
%
get_functions_without_return_as_last_statement(FunctionsWithoutReturn) :-
    findall(FunctionId, functiondef1(FunctionId), FunctionIds),
    findall(FunctionId,
        (member(FunctionId, FunctionIds),
        \+ has_return_as_last_statement(FunctionId)),
        FunctionsWithoutReturn
    ).

% has_return_as_last_statement(+FunctionId)
%
% Checks if the last statement in a function is a return statement.
% - FunctionId: The ID of the function node to check.
% - Succeeds if the function's body ends with a return statement.
%
has_return_as_last_statement(FunctionId) :-
    nonvar(FunctionId),
    node(functiondef, FunctionId, Children, _),
    member(body:BodyIds, Children),
    last(BodyIds, LastBodyId),
    node(return, LastBodyId, _, _).

% last(+List, -LastElement)
%
% Finds the last element of a list.
% - List: The input list.
% - LastElement: The last element of the list.
%
last([LastElement], LastElement) :- !.
last([_|Tail], LastElement) :-
    last(Tail, LastElement).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Checking Unused Loop Vars %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% has_all_loop_have_used_vars/0
%
% Checks if all `for` loops have only used variables.
% - Fails immediately if any loop has unused variables.
% - Succeeds with a single `true` if all loops are valid.
%
has_all_loop_have_used_vars :-
    ( current_predicate(for1/1)
        ->  findall(ForId, for1(ForId), ForIds),
            check_loops(ForIds)
        ;   true
    ).

% check_loops(+ForIds)
%
% Checks if all loops in the list have used variables.
% - Fails immediately if any loop has unused variables.
% - Succeeds if all loops are valid.
%
check_loops([]).
check_loops([ForId | Rest]) :-
    ( loop_var_unused(ForId, _)
        -> fail
        ; true
    ),
    check_loops(Rest).

% display_all_unused_loop_vars/0
%
% Finds and reports all loops with unused loop variables.
% - Outputs loop IDs and unused variable names for each problematic loop.
% - If no loops have unused variables, prints a confirmation message.
% - Always succeeds after checking all loops.
%
display_all_unused_loop_vars :-
    format('----------------------------------------------~n'),
    ( current_predicate(for1/1)
        ->  get_loop_with_unused_vars(LoopsWithUnusedVars),
            ( LoopsWithUnusedVars = []
                ->  format('All loops have used variables.~n', [])
                ;   format('Some loops have unused variables.~n'),
                    forall(member(ForId-UnusedVars, LoopsWithUnusedVars), (
                        format('  - Loop ~w has unused variable(s): ~w~n', [ForId, UnusedVars])
                    )
                ), !
            )
        ; format('No loop found (for1/1 not defined).~n')
    ),
    format('----------------------------------------------~n').

% get_loop_with_unused_vars(-LoopsWithUnusedVars)
%
% Retrieves all loops that have unused loop variables.
% - Returns a list of `ForId-UnusedVars` pairs for violating loops.
%   - `ForId`: The unique ID of the loop.
%   - `UnusedVars`: A list of unused loop variables.
% - Returns an empty list if no loops have unused variables.
%
get_loop_with_unused_vars(LoopsWithUnusedVars) :-
    findall(ForId-UnusedVars,
        ( for1(ForId),
          loop_var_unused(ForId, UnusedVars)
        ),
        LoopsWithUnusedVars).

% loop_var_unused(+ForId, -UnusedVars)
%
% Checks if the loop variables in a `for` loop are unused in its body.
% - ForId: The ID of the `for` loop node.
% - UnusedVars: List of unused variable names.
% - Succeeds if at least one loop variable is unused in the loop body.
%
loop_var_unused(ForId, UnusedVars) :-
    nonvar(ForId),
    node(for, ForId, Children, _),
    member(target:TargetId, Children), % TargetId => Id(s) of loop variable(s)
    extract_variables(TargetId, VarNames), % Extract the variables name
    exclude(is_ignored_var, VarNames, FilteredVarNames), % Ignore variables like "_"
    member(body:BodyId, Children), % Get Body of the Loop
    find_unused_vars(FilteredVarNames, BodyId, UnusedVars), % Check if these variables are used in the body
    UnusedVars \== []. % True if at least one loop variable is unused

% is_ignored_var(+VarName)
%
% Checks if a variable should be ignored (e.g., "_").
% - VarName: The variable name to check.
%
is_ignored_var("_").

% find_unused_vars(+VarNames, +BodyId, -UnusedVars)
%
% Finds variables from VarNames that are unused in the loop body.
% - VarNames: List of variable names to check.
% - BodyId: ID of the loop body.
% - UnusedVars: List of unused variable names.
%
find_unused_vars(VarNames, BodyId, UnusedVars) :-
    findall(VarName, 
        (member(VarName, VarNames), 
            \+ var_used_in_body(VarName, BodyId)), 
        UnusedVars).

% extract_variables(+TargetId, -VarNames)
%
% Extracts variable names from a loop target (e.g., single variable or tuple).
% - TargetId: The ID of the target node.
% - VarNames: The list of variable names extracted.
%
extract_variables(TargetId, VarNames) :-
    node(name, TargetId, _, TargetAttrs),
    member(id:VarName, TargetAttrs),
    VarNames = [VarName], !.
extract_variables(TargetId, VarNames) :-
    node(tuple, TargetId, TargetChildren, _),
    member(elts:VarIds, TargetChildren),
    maplist(extract_var_name, VarIds, VarNames), !.

% extract_var_name(+VarId, -VarName)
%
% Extracts the name of a variable from its node.
% - VarId: The ID of the variable node.
% - VarName: The name of the variable.
%
extract_var_name(VarId, VarName) :-
    node(_, VarId, _, VarAttrs),
    member(id:VarName, VarAttrs).

% var_used_in_body(+VarName, +BodyIds)
%
% Checks if a variable is used in a list of body nodes.
% - VarName: The variable name to check.
% - BodyIds: The list of body node IDs.
%
var_used_in_body(VarName, BodyIds) :-
    is_list(BodyIds),
    member(ChildId, BodyIds),
    var_used_in_body(VarName, ChildId).
var_used_in_body(VarName, BodyId) :-
    node(_, BodyId, BodyChildren, BodyAttrs),
    (  member(id:VarName, BodyAttrs)    % Variable is used => true
    ;  member(_:ChildId, BodyChildren), % Check children recursively
       var_used_in_body(VarName, ChildId)
    ).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Step 3 - Checking Accumulator Pattern %%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% has_accumulator_patterns/0
%
% Check if at least one function has the accumulator pattern
% Return True in this case, False otherwise.
%
has_accumulator_patterns :-
    findall([FunctionId, FuncName, AccVar], 
        find_function_with_accumulator(FunctionId, FuncName, AccVar), 
        Results),
    Results \= [].

% display_accumulator_patterns/0
%
% Displays detected accumulator patterns in functions
% - Prints results in formatted output with section separators
%
display_accumulator_patterns :-
    format('----------------------------------------------~n'),
    ( get_functions_with_accumulator(Results),
      Results \== []
        ->  length(Results, Count),
            format('Found ~d accumulator patterns:~n', [Count]),
            foreach(member([FId,Name,AVar], Results),
                format('  - Function "~w" (ID ~w)~n      => Accumulator: "~w"~n', 
                [Name,FId,AVar]))
        ; format('No accumulator patterns found~n')
    ),
    format('----------------------------------------------~n').

% get_functions_with_accumulator(-Results)
%
% Retrieves all functions that use an accumulator pattern.
% - Returns a list of `[FunctionId, FuncName, AccVar]` lists for functions using an accumulator.
%   - `FunctionId`: The unique ID of the function.
%   - `FuncName`: The name of the function.
%   - `AccVar`: The accumulator variable used in the function.
% - Returns an empty list if no functions use an accumulator pattern.
%
get_functions_with_accumulator(Results) :-
    findall([FunctionId, FuncName, AccVar], 
        find_function_with_accumulator(FunctionId, FuncName, AccVar), 
        Results).

% find_function_with_accumulator(+FID, +FuncName, -AccVar)
%
% Identifies functions following the accumulator pattern
% - FID: Function node ID
% - FuncName: Name of the function
% - AccVar: Accumulator variable name
%
find_function_with_accumulator(FID, FuncName, AccVar) :-
    node(functiondef, FID, Children, Attrs),
    member(name:FuncName, Attrs),
    member(body:BodyIds, Children),
    has_accumulator_initialization(BodyIds, AccVar),
    has_accumulator_loop(BodyIds, AccVar),
    has_accumulator_return(BodyIds, AccVar).

% has_accumulator_initialization(+BodyIds, -AccVar)
%
% Verifies accumulator initialization through assignment
% - BodyIds: List of body statement IDs
% - AccVar: Unifies with found accumulator variable
%
has_accumulator_initialization(BodyIds, AccVar) :-
    member(AssignId, BodyIds),
    node(assign, AssignId, Children, _),
    member(targets:[TargetId], Children),
    node(name, TargetId, _, Attrs),
    member(id:AccVar, Attrs), !.

% has_accumulator_loop(+BodyIds, -AccVar)
%
% Detects loops containing accumulator updates
% - BodyIds: List of body statement IDs
% - AccVar: Accumulator variable to check
%
has_accumulator_loop(BodyIds, AccVar) :-
    member(LoopId, BodyIds),
    (node(for, LoopId, LoopChildren, _) ; node(while, LoopId, LoopChildren, _)),
    member(body:LoopBody, LoopChildren),
    deep_contains_assignment(LoopBody, AccVar), !.

% deep_contains_assignment(+Nodes, +AccVar)
%
% Recursively checks nodes for accumulator assignments
% - Nodes: List of AST nodes to inspect
% - AccVar: Accumulator variable name
%
deep_contains_assignment([], _).
deep_contains_assignment([Child|Rest], AccVar) :-
    process_child(Child, AccVar),
    deep_contains_assignment(Rest, AccVar).

% process_child(+Node, +AccVar)
%
% Processes AST node children for accumulator assignments
% - Node: AST node or key-value pair
% - AccVar: Accumulator variable name
%
process_child(KeyValue, AccVar) :-
    KeyValue = (_:Value),
    ( is_list(Value)
        -> deep_contains_assignment(Value, AccVar)
        ;  deep_contains_assignment([Value], AccVar)
    ).
process_child(Node, AccVar) :-
    is_assignment(Node, AccVar).
process_child(Node, AccVar) :-
    node(_, Node, Children, _),
    deep_contains_assignment(Children, AccVar).

% is_assignment(+Node, +AccVar)
%
% Checks if node is valid accumulator assignment
% - Node: AST node ID
% - AccVar: Accumulator variable name
%
is_assignment(Node, AccVar) :-
    node(Type, Node, Children, _),
    (Type = augassign ; Type = assign),
    ( Type = augassign 
        -> member(target:VarId, Children)
        ;  member(targets:[VarId], Children)
    ),
    get_target_base(VarId, AccVar).

% get_target_base(+VarId, -AccVar)
%
% Extracts base variable name from complex expressions
% - VarId: Variable node ID
% - AccVar: Unified with base variable name
%
get_target_base(VarId, AccVar) :-
    ( node(name, VarId, _, Attrs)
        ->  member(id:AccVar, Attrs)
        ; ( node(subscript, VarId, Children, _) ; node(attribute, VarId, Children, _)),
            member(value:BaseId, Children),
            node(name, BaseId, _, Attrs),
            member(id:AccVar, Attrs)
    ).

% has_accumulator_return(+BodyIds, +AccVar)
%
% Verifies accumulator is returned
% - BodyIds: List of body statement IDs
% - AccVar: Accumulator variable name
%
has_accumulator_return(BodyIds, AccVar) :-
    member(ReturnId, BodyIds),
    node(return, ReturnId, Children, _),
    member(value:ExprId, Children),
    deep_contains_var(ExprId, AccVar), !.

% deep_contains_var(+Node, +AccVar)
%
% Recursively checks for variable presence in expression
% - Node: AST node ID to inspect
% - AccVar: Variable name to find
%
deep_contains_var(Node, AccVar) :-
    node(name, Node, _, Attrs),
    member(id:AccVar, Attrs).
deep_contains_var(Node, AccVar) :-
    node(_, Node, Children, _),
    member(Child, Children),
    deep_contains_var(Child, AccVar).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%% Step 4 - Coding Flaws %%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Checking Empty Constructor %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% has_empty_init/0
%
% Checks if at least one class has an empty __init__ method.
% - Succeeds (returns true) if at least one class has an empty __init__ method.
% - Fails (returns false) if no class has an empty __init__ method.
%
has_empty_init :-
    node(classdef, ClassId, _, _),
    has_empty_init(ClassId), !.

% display_empty_init/0
%
% Prints warnings for all classes with empty __init__ methods.
% - Outputs class names and IDs with empty __init__ methods.
% - If no classes have empty __init__ methods, prints a confirmation message.
% - Always succeeds after checking all classes.
%
display_empty_init :-
    format('----------------------------------------------~n'),
    ( current_predicate(classdef1/1)
        ->  get_classes_with_empty_init(ClassesWithEmptyInit),
            ( ClassesWithEmptyInit = []
                ->  format('All classes have non-empty __init__ methods.~n', [])
                ;   format('Some classes have empty __init__ methods.~n'),
                    forall(
                        member(NameClass-ClassId, ClassesWithEmptyInit),
                        format('  - Class "~w" (ID ~w) has an empty __init__ method.~n', [NameClass, ClassId])
                    )
            )
        ;   format('No classes found (classdef1/1 not defined).~n')
    ),
    format('----------------------------------------------~n').

% get_classes_with_empty_init(-ClassesWithEmptyInit)
%
% Retrieves all classes that have an empty `__init__` method.
% - Returns a list of `NameClass-ClassId` pairs for violating classes.
%   - `NameClass`: The name of the class.
%   - `ClassId`: The unique ID of the class.
% - Returns an empty list if no classes have an empty `__init__` method.
%
get_classes_with_empty_init(ClassesWithEmptyInit) :-
    findall(
        NameClass-ClassId,
        (
            node(classdef, ClassId, _, Attr),
            has_empty_init(ClassId),
            member(name:NameClass, Attr)
        ),
        ClassesWithEmptyInit
    ).

% has_empty_init(+ClassId)
%
% Checks if a class has an empty __init__ method.
% - ClassId: The ID of the class node to check.
% - Succeeds if the class contains an __init__ method with only a 'pass' statement.
%
has_empty_init(ClassId) :-
    node(classdef, ClassId, Children, _), % Get Class Node
    member(body:BodyIds, Children),
    member(MethodId, BodyIds),
    node(functiondef, MethodId, MethodChildren, MethodAttrs), % Get "__init__" method
    member(name:"__init__", MethodAttrs),
    member(body:MethodBodyIds, MethodChildren),
    length(MethodBodyIds, 1),
    MethodBodyIds = [MethodBodyId],
    node(pass, MethodBodyId, _, _),
    !.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Check __init__ Methods for Returns %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% has_init_returns_object/0
%
% Succeeds if any class's __init__ method returns a value (self or class instance).
%
has_init_returns_object :-
    class_init_returns_object(_, _),
    !.

% display_init_returns_object/0
%
% Prints all classes whose __init__ method returns a value, along with the returned values.
%
display_init_returns_object :-
    format('-----------------------------------------------~n'),
    ( current_predicate(classdef1/1)
        ->  get_classes_with_init_return_object(Classes),
            ( Classes = [] 
                ->  format('No __init__ methods return objects.~n')
                ;   format('Classes with __init__ returning values~n'),
                    forall(member(class(N, Rs), Classes),
                        format('  - Class "~w" returns: ~w~n', [N, Rs]))
            )
        ;   format('No classes found (classdef1/1 not defined).~n')
    ),
    format('-----------------------------------------------~n').

% get_classes_with_init_return_object(-Classes)
%
% Retrieves all classes where the `__init__` method returns an object.
% - Returns a list of `class(Name, Returns)` tuples for violating classes.
%   - `Name`: The name of the class.
%   - `Returns`: A list of values returned by the `__init__` method.
% - Returns an empty list if no classes have an `__init__` method that returns an object.
%
get_classes_with_init_return_object(Classes) :-
    findall(class(Name, Returns), (
        node(classdef, ClassId, _, Attrs),
        member(name:Name, Attrs),
        findall(Val, class_init_returns_object(ClassId, Val), Returns),
        Returns \= []
    ), Classes).

% class_init_returns_object(+ClassId, -ReturnValue)
%
% True if the class with ID ClassId has an __init__ method that returns ReturnValue.
%
class_init_returns_object(ClassId, Value) :-
    % Find __init__ method in class body
    node(classdef, ClassId, ClassChildren, _),
    member(body:BodyIds, ClassChildren),
    member(MethodId, BodyIds),
    node(functiondef, MethodId, _, MethodAttrs),
    member(name:"__init__", MethodAttrs),
    % Check for return statements with value
    node(functiondef, MethodId, InitChildren, _),
    member(body:MethodBody, InitChildren),
    has_return_value(MethodBody, ClassId, Value).

% has_return_value(+NodeIds, +ClassId, -Value)
%
% Recursively checks AST nodes for return statements with a value.
%
has_return_value([NodeId|_], ClassId, Value) :-
    node(return, NodeId, Attrs, _),
    member(value:ValId, Attrs),
    extract_value(ValId, ClassId, Value).
has_return_value([NodeId|Rest], ClassId, Value) :-
    ( node(_, NodeId, Props, _),
        ( member(body:SubNodes, Props) ;  member(orelse:SubNodes, Props) ),
        has_return_value(SubNodes, ClassId, Value)
    ;  has_return_value(Rest, ClassId, Value)
    ).

% extract_value(+ValueId, +ClassId, -Value)
%
% Extracts the returned value (self or class instance).
%
extract_value(ValId, ClassId, Value) :-
    (   node(name, ValId, _, Attrs), 
        member(id:Value, Attrs)
    ;   node(call, ValId, CallAttrs, _),
        member(func:FuncId, CallAttrs),
        node(name, FuncId, _, FuncAttrs),
        member(id:ClassName, FuncAttrs),
        node(classdef, ClassId, _, ClassAttrs),
        member(name:ClassName, ClassAttrs),
        Value = ClassName
    ).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Checking Parameter Reassignment %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%
%%% Detects parameter reassignments (assign/augassign) in function bodies.  
%%% Deep-scans AST with recursive checks to flag arguments modified post-declaration.
%%%

% has_erase_args/0
%
% Check if at least one function reassigns any of its parameters.
% - Succeeds (returns true) if any function reassigns a parameter.
% - Fails (returns false) if no function reassigns its parameters.
%
has_erase_args :-
    node(functiondef, FID, _, _),
    get_reassigned_param(FID, _), !.

% display_erase_args/0
%
% Lists all functions that reassign their parameters along with the specific parameters being reassigned.
% - Outputs function names, IDs, and reassigned parameters for each problematic function.
% - If no functions reassign parameters, prints a confirmation message.
% - Always succeeds after checking all functions.
%
display_erase_args :-
    format('-----------------------------------------------------~n'),
    ( current_predicate(functiondef1/1)
        ->  get_functions_that_erase_args(FunctionsWithReassignedParams),
            ( FunctionsWithReassignedParams = []
                ->  format('No functions reassign their parameters.~n', [])
                ;   format('Some functions reassign their parameters.~n'),
                    forall(member(Name-FID-ReassignedParams, FunctionsWithReassignedParams), (
                        format('  - Function "~w" (ID ~w) reassigns parameter(s): ~w~n', [Name, FID, ReassignedParams])
                    ))
                )
        ;   format('No functions found (functiondef1/1 not defined).~n')
    ),
    format('-----------------------------------------------------~n').

% get_functions_that_erase_args(-FunctionsWithReassignedParams)
%
% Retrieves all functions that reassign their parameters (erase arguments).
% - Returns a list of `Name-FID-ReassignedParams` tuples for violating functions.
%   - `Name`: The name of the function.
%   - `FID`: The function's unique ID.
%   - `ReassignedParams`: A list of parameter names that are reassigned within the function.
% - Returns an empty list if no functions reassign their parameters.
%
get_functions_that_erase_args(FunctionsWithReassignedParams) :-
    findall(Name-FID-ReassignedParams,
        (node(functiondef, FID, _, Attrs),
            member(name:Name, Attrs),
            findall(ParamName, get_reassigned_param(FID, ParamName), ReassignedParams),
            ReassignedParams \= []),
        FunctionsWithReassignedParams).

% get_reassigned_param(+FID, -ParamName)
%
% Identifies a specific parameter that is reassigned within a function.
% - FID: The ID of the function to check.
% - ParamName: Unified with the name of a reassigned parameter.
%
get_reassigned_param(FID, ParamName) :-
    node(functiondef, FID, Props, _),
    member(args:ArgsId, Props),
    get_args_names(ArgsId, ArgNames),
    member(body:BodyNodes, Props),
    member(BodyNodeId, BodyNodes),
    find_reassigned_param(BodyNodeId, ArgNames, ParamName).

% get_args_names(+ArgsId, -ArgNames)
%
% Retrieves all argument names from a function definition.
% - ArgsId: The ID of the arguments node.
% - ArgNames: Unified with a list of argument names.
%
get_args_names(ArgsId, ArgNames) :-
    node(arguments, ArgsId, Props, _),
    member(args:Args, Props),
    extract_arg_names(Args, ArgNames).

% extract_arg_names(+Args, -ArgNames)
%
% Extracts parameter names from a list of argument IDs.
% - Args: List of argument node IDs
% - ArgNames: Unified with list of extracted argument names
%
extract_arg_names([], []).
extract_arg_names([ArgId|Args], [ArgName|ArgNames]) :-
    node(arg, ArgId, _, Attrs),
    member(arg:ArgName, Attrs),
    extract_arg_names(Args, ArgNames).

% find_reassigned_param(+NodeId, +ArgNames, -ParamName)
%
% Identifies a specific parameter that is reassigned within a node or its descendants.
% - NodeId: ID of the node to check
% - ArgNames: List of parameter names to check for reassignment
% - ParamName: Unified with the name of a reassigned parameter
%
% Checks if a parameter is reassigned via a standard assignment (e.g., `x = ...`).
find_reassigned_param(NodeId, ArgNames, ParamName) :-
    node(assign, NodeId, Props, _), % Assignement Node
    member(targets:Targets, Props), % Targets is a list of ID
    member(TargetId, Targets), % Extract a single target ID
    node(name, TargetId, _, Attrs),
    member(id:ParamName, Attrs),
    member(ParamName, ArgNames),
    !.
% Checks if a parameter is reassigned via an augmented assignment (e.g., `x += ...`).
find_reassigned_param(NodeId, ArgNames, ParamName) :-
    node(augassign, NodeId, Props, _),
    member(target:TargetId, Props), % Target is a single ID
    node(name, TargetId, _, Attrs),
    member(id:ParamName, Attrs),
    member(ParamName, ArgNames),
    !.
% Recursively checks child nodes for parameter reassignment.
find_reassigned_param(NodeId, ArgNames, ParamName) :-
    children(NodeId, ChildrenIds),
    member(SubNodeId, ChildrenIds),
    find_reassigned_param(SubNodeId, ArgNames, ParamName). % Recursive call


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Increment in For-Loops %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%
%%% Detects manual loop variable increments (augassign/assign) in for-loops.  
%%% Non-trivial recursive checks for updates in nested conditionals/structures.
%%%

% has_incr_in_for_loops/0
%
% Checks if any for-loop in the AST contains manual increments of its loop variable(s).
% - Succeeds if at least one for-loop updates its loop variable.
% - Fails if no for-loops update their loop variables.
%
has_incr_in_for_loops :-
    node(for, ForId, _, _),
    has_loop_var_increment(ForId, _), !.

% display_incr_in_for_loops/0
%
% Prints all for-loops that manually increment their loop variable(s).
% - Outputs the loop ID and variable name for each violation.
% - If no loops manually increment their variables, prints a confirmation message.
% - Always succeeds after traversing the entire AST.
%
display_incr_in_for_loops :-
    format('-----------------------------------------------------~n'),
    ( current_predicate(for1/1)
        ->  get_loop_with_var_increment(LoopsWithManualIncrement),
            ( LoopsWithManualIncrement = []
                ->  format('No for-loops manually increment their loop variables.~n', [])
                ;   format('Some for-loops manually increment their loop variables.~n'),
                    forall(member(ForId-LoopVarName, LoopsWithManualIncrement), (
                        format('  - For-loop (ID ~w) updates variable "~w".~n', [ForId, LoopVarName])
                    ))
                )
        ;   format('No for-loops found (for1/1 not defined).~n')
    ),
    format('-----------------------------------------------------~n').

% get_loop_with_var_increment(-LoopsWithManualIncrement)
%
% Retrieves all loops where a loop variable is manually incremented.
% - Returns a list of `ForId-LoopVarName` pairs for violating loops.
%   - `ForId`: The unique ID of the loop.
%   - `LoopVarName`: The name of the loop variable being manually incremented.
% - Returns an empty list if no loops have manual variable increments.
%
get_loop_with_var_increment(LoopsWithManualIncrement) :-
    findall(ForId-LoopVarName,
        (for1(ForId),
            has_loop_var_increment(ForId, UpdatedVars),
            member(LoopVarName, UpdatedVars)
        ),
        LoopsWithManualIncrement).

% has_loop_var_increment(+ForId, -UpdatedVars)
%
% Checks which loop variables are updated in a for-loop.
% - ForId: ID of the for-loop node to check.
% - UpdatedVars: List of variable names that are updated in the loop body.
% - Succeeds if at least one loop variable is updated.
%
has_loop_var_increment(ForId, UpdatedVars) :-
    node(for, ForId, ForProps, _),
    member(target:TargetId, ForProps),
    get_loop_var_names(TargetId, LoopVarNames),
    member(body:BodyNodes, ForProps),
    findall(VarName, (
        member(VarName, LoopVarNames),
        member(BodyNodeId, BodyNodes),
        updates_variable(BodyNodeId, VarName)
    ), UpdatedVars),
    UpdatedVars \= [].

% get_loop_var_names(+TargetId, -VarNames)
%
% Extracts loop variable names from a for-loop target node.
% - TargetId: ID of the target node (name or tuple).
% - VarNames: List of variable names extracted from the target.
%
get_loop_var_names(TargetId, [VarName]) :-
    node(name, TargetId, _, Attrs),
    member(id:VarName, Attrs), !.
get_loop_var_names(TargetId, VarNames) :-
    node(tuple, TargetId, Children, _),
    member(elts:Elements, Children),
    findall(VarName, (
        member(ElementId, Elements),
        node(name, ElementId, _, Attrs),
        member(id:VarName, Attrs)
    ), VarNames).

% updates_variable(+NodeId, +VarName)
%
% Checks if a node updates a specific variable (e.g., += or =).
% - NodeId: ID of the node to check.
% - VarName: Name of the variable to check for updates.
% - Succeeds if the variable is updated in this node or nested structures.
%
updates_variable(NodeId, VarName) :-
    % Case 1: Augmented assignment (x += y)
    node(augassign, NodeId, Props, _),
    member(target:TargetId, Props),
    node(name, TargetId, _, Attrs),
    member(id:VarName, Attrs),
    !.
updates_variable(NodeId, VarName) :-
    % Case 2: Simple assignment (x = ...)
    node(assign, NodeId, Props, _),
    member(targets:Targets, Props),
    member(TargetId, Targets),
    node(name, TargetId, _, Attrs),
    member(id:VarName, Attrs),
    !.
updates_variable(NodeId, VarName) :-
    % Case 3: Recursive check in all child nodes
    node(_, NodeId, Props, _),
    member(_Key:Value, Props),
    is_list(Value),
    member(SubNodeId, Value),
    updates_variable(SubNodeId, VarName).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Early Return Misconception %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%
%%% This implementation detects early returns in loops, which are considered a bad practice
%%% in code design. An early return in a loop can lead to unexpected behavior and make the
%%% code harder to understand and maintain. This predicate identifies functions where a
%%% return statement is placed inside a loop (for or while), even if there is no code after
%%% the loop. This is a deliberate design choice to enforce cleaner and more predictable
%%% control flow.
%%%

% has_early_return/0
%
% Checks if any function in the AST contains an early return inside a loop.
% - Succeeds if at least one function contains an early return in a loop.
% - Fails if no function contains an early return in a loop.
%
has_early_return :-
    node(functiondef, FId, _, _),
    has_early_return_misconception(FId), !.

% display_early_return/0
%
% Prints all functions containing early returns in loops.
% - Outputs the function names and IDs for each violation.
% - If no functions contain early returns in loops, prints a confirmation message.
% - Always succeeds after traversing the entire AST.
%
display_early_return :-
    format('-----------------------------------------------------~n'),
    ( current_predicate(functiondef1/1)
        ->  get_functions_with_early_return_misconception(FunctionsWithEarlyReturn),
            ( FunctionsWithEarlyReturn = []
                ->  format('No functions contain an early return in a loop.~n', [])
                ;   format('Some functions contain an early return in a loop.~n'),
                    forall(member(Name-FId, FunctionsWithEarlyReturn), (
                        format('  - Function "~w" (ID ~w) contains an early return in a loop.~n', [Name, FId])
                    ))
                )
        ;   format('No functions found (functiondef1/1 not defined).~n')
    ),
    format('-----------------------------------------------------~n').

% get_functions_with_early_return_misconception(-FunctionsWithEarlyReturn)
%
% Retrieves all functions that have an early return misconception.
% - Returns a list of `Name-FId` pairs for violating functions.
%   - `Name`: The name of the function.
%   - `FId`: The function's unique ID.
% - Returns an empty list if no functions have an early return misconception.
%
get_functions_with_early_return_misconception(FunctionsWithEarlyReturn) :-
    findall(Name-FId,
        (node(functiondef, FId, _, Attrs),
            member(name:Name, Attrs),
            has_early_return_misconception(FId)),
        FunctionsWithEarlyReturn).

% loop_node(+NodeId)
%
% Checks if a node represents a loop structure (for or while).
% - NodeId: ID of the node to check.
% - Succeeds if the node is a for or while loop.
%
loop_node(NodeId) :- 
    node(Type, NodeId, _, _), 
    member(Type, [for, while]).

% has_early_return_misconception(+FId)
%
% Checks if a function contains problematic return patterns in loops.
% - FId: ID of the function node to check
% - Succeeds if either:
%   1. Loop contains return with subsequent code (unreachable)
%   2. Nested loop contains return statement
%
has_early_return_misconception(FId) :-
    node(functiondef, FId, Props, _),
    member(body:Body, Props),
    contains_early_return_in_loop(Body).

% contains_early_return_in_loop(+Nodes)
%
% Recursively checks for early returns in loops within a list of nodes.
% - Nodes: List of node IDs to check.
% - Succeeds if an early return is found in a loop.
%
contains_early_return_in_loop([]) :-
    fail.
contains_early_return_in_loop([NodeId|_]) :-
    loop_node(NodeId),
    node(_, NodeId, Props, _),
    member(body:Body, Props),
    contains_return(Body),
    !.
contains_early_return_in_loop([NodeId|_]) :-
    node(_, NodeId, Props, _),
    member(Prop, Props),
    Prop =.. [_, Value],
    is_list(Value),
    contains_early_return_in_loop(Value),
    !.
contains_early_return_in_loop([_|Rest]) :-
    contains_early_return_in_loop(Rest).

% contains_return(+Nodes)
%
% Recursively checks for return statements in a list of nodes and their children.
% - Nodes: List of node IDs to check.
% - Succeeds if a return statement is found in the list or its nested structures.
%
contains_return([]) :-
    fail.
contains_return([NodeId|_]) :- 
    node(return, NodeId, _, _),
    !.
contains_return([NodeId|_]) :-
    node(_, NodeId, Props, _),
    member(body:SubNodes, Props),
    contains_return(SubNodes),
    !.
contains_return([_|Rest]) :-
    contains_return(Rest).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Too Much Indentation %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% has_too_much_indent/0
%
% Checks if at least one function have 3 or more levels of indentation.
% - Succeeds (true) if any function has 3 or more levels of indentation.
% - Fails (false) if no function exceeds the indentation limit.
%
has_too_much_indent :-
    node(functiondef, FId, _, _),
    function_has_too_much_indent(FId, _), !.

% display_too_much_indent/0
%
% Prints all functions with 3 or more levels of indentation.
% - Outputs function names and IDs for each violation.
% - If no functions have excessive indentation, prints a confirmation message.
% - Always succeeds after traversing the entire AST.
%
display_too_much_indent :-
    format('-----------------------------------------------------~n'),
    ( current_predicate(functiondef1/1)
        ->  get_functions_with_too_much_indent(FunctionsWithTooMuchIndent),
            ( FunctionsWithTooMuchIndent = []
                ->  format('No functions have 3 or more levels of indentation.~n', [])
                ;   format('Some functions have too many levels of indentation.~n'),
                    forall(member(Name-FId-NbNestedLvl, FunctionsWithTooMuchIndent), (
                        format('  - Function "~w" (ID ~w) has ~w nesting levels.~n', [Name, FId, NbNestedLvl])
                    ))
            )
    ;   format('No functions found (functiondef1/1 not defined).~n')
    ),
    format('-----------------------------------------------------~n').

% get_functions_with_too_much_indent(-FunctionsWithTooMuchIndent)
%
% Retrieves all functions that have too much indentation (excessive nesting).
% - Returns a list of `Name-FId-NbNestedLvl` tuples for violating functions.
%   - `Name`: The name of the function.
%   - `FId`: The function's unique ID.
%   - `NbNestedLvl`: The number of nested levels in the function.
% - Returns an empty list if no functions have too much indentation.
%
get_functions_with_too_much_indent(FunctionsWithTooMuchIndent) :-
    findall(Name-FId-NbNestedLvl,
        (node(functiondef, FId, _, Attrs),
            member(name:Name, Attrs),
            function_has_too_much_indent(FId, NbNestedLvl)
        ),
        FunctionsWithTooMuchIndent).

% function_has_too_much_indent(+FId)
%
% Checks if a function exceeds the indentation limit.
% - FId: ID of the function node.
% - Succeeds if the function has 3 or more levels of indentation.
%
function_has_too_much_indent(FId, NbNestedLvl) :-
    node(functiondef, FId, Props, _),
    member(body:Body, Props),
    count_max_nesting(Body, 0, NbNestedLvl), % Get Max Number of Nesting in all the Body
    NbNestedLvl >= 3, % If more than two => too Much
    !.

% count_max_nesting(+Body, +CurrentLevel, -MaxLevel)
%
% Computes the maximum indentation level in a list of nodes.
% - Nodes: List of node IDs to check.
% - CurrentLevel: Current indentation level.
% - MaxLevel: Maximum indentation level found.
%
count_max_nesting([], CurrentLevel, CurrentLevel).
count_max_nesting([NodeId|Rest], CurrentLevel, MaxLevel) :-
    node_nesting_level(NodeId, CurrentLevel, NodeMaxLevel), % Nesting Level of the NodeID
    count_max_nesting(Rest, CurrentLevel, RestMaxLevel), % Nesting Level of the Rest (Recursively)
    MaxLevel is max(NodeMaxLevel, RestMaxLevel). % Take the maximum

% node_nesting_level(+NodeId, +CurrentLevel, -MaxLevel)
%
% Computes the indentation level for a given node.
% - NodeId: ID of the node to check.
% - CurrentLevel: Current indentation level.
% - MaxLevel: Maximum indentation level for this node and its children.
%
node_nesting_level(NodeId, CurrentLevel, MaxLevel) :-
    node(Type, NodeId, _, _),
    member(Type, [if, for, while]), % Condition Structure (nested)
    node(_, NodeId, Children, _),
    NewLevel is CurrentLevel + 1,
    % Check if the node has a body (main block of the control structure)
    ( member(body:Body, Children)
        ->  count_max_nesting(Body, NewLevel, BodyMaxLevel) % Recursively compute the maximum nesting level for the body
        ;  BodyMaxLevel = NewLevel % If no body, the current level is the maximum
    ),
    % Check if the node has an else clause (for if statements)
    ( member(orelse:Else, Children)
        ->  count_max_nesting(Else, NewLevel, ElseMaxLevel) % Recursively compute the maximum nesting level for the else clause
        ;   ElseMaxLevel = NewLevel % If no else clause, the current level is the maximum
    ),
    MaxLevel is max(BodyMaxLevel, ElseMaxLevel).
node_nesting_level(_, CurrentLevel, CurrentLevel).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Print Instead of Return %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%
%% This implementation checks whether the last statement in a function body is a print node (i.e., a call to the print function).
%% The analysis is performed as follows:
%% 1. Control Structure Handling:
%%   - If the last statement is a control structure node (e.g., for, while, try-except, or if-else),
%%     the function recursively checks the last statement within those structures.
%%   - If at least one of the last statements in any control structure is a print statement, the pattern is detected.
%% 2. Return Statement Validation:
%%   - The function ensures that there is no explicit return statement in the body of the function,
%%     as the presence of a return would invalidate the pattern being checked.
%%

% has_print_instead_return/0
%
% Check if at least one function uses `print` as a substitute for `return`.
% - Succeeds (true) if any function ends with `print` and lacks a proper `return` statement.
% - Fails (false) if no function misuses `print` in place of `return`.
%
has_print_instead_return :-
    node(functiondef, FunctionId, _, _),
    has_print_return_misconception(FunctionId), !.

% display_print_instead_return/0
%
% Lists all functions that misuse `print` instead of `return`.
% - Outputs the function name and ID for each violation.
% - If no functions misuse `print`, prints a confirmation message.
% - Always succeeds after traversing the entire AST.
%
display_print_instead_return :-
    format('-----------------------------------------------------~n'),
    ( current_predicate(functiondef1/1)
        ->  get_functions_with_print_misconception(FunctionsWithPrintReturnMisconception),
            ( FunctionsWithPrintReturnMisconception = []
                ->  format('No functions misuse print instead of return.~n', [])
                ;   format('Some functions misuse print instead of return.~n'),
                    forall(member(Name-FId, FunctionsWithPrintReturnMisconception), (
                        format('  - Function "~w" (ID ~w) uses print instead of return.~n', [Name, FId])
                    ))
            )
        ;   format('No functions found (functiondef1/1 not defined).~n')
    ),
    format('-----------------------------------------------------~n').

% get_functions_with_print_misconception(-FunctionsWithPrintReturnMisconception)
%
% Retrieves all functions that misuse `print` instead of `return`.
% - Returns a list of `Name-FId` pairs for violating functions.
% - Returns an empty list if no violations are found.
%
get_functions_with_print_misconception(FunctionsWithPrintReturnMisconception) :-
    findall(Name-FId,
        (node(functiondef, FId, _, Attrs),
            member(name:Name, Attrs),
            has_print_return_misconception(FId)
        ),
        FunctionsWithPrintReturnMisconception
    ).

% has_print_return_misconception(+FID)
%
% Checks if a function misuses `print` instead of `return`.
% - Succeeds if the function ends with a `print` statement without an explicit `return`.
% - Fails otherwise.
%
has_print_return_misconception(FID) :-
    node(functiondef, FID, Props, _),
    member(body:BodyNodes, Props),
    \+ has_explicit_return(BodyNodes),
    ends_with_print(BodyNodes),
    !.

% has_explicit_return(+BodyNodes)
%
% Checks if there is an explicit `return` statement in the function body.
% - Succeeds if any node in `BodyNodes` is a `return` statement.
% - Fails otherwise.
%
has_explicit_return(BodyNodes) :-
    member(NodeId, BodyNodes),
    node(return, NodeId, _, _).

% ends_with_print(+BodyNodes)
%
% Checks if the function body ends with a `print` statement.
% - Succeeds if the last node in `BodyNodes` is a `print` statement.
% - Fails otherwise.
%
ends_with_print(BodyNodes) :-
    last(BodyNodes, LastNodeId),
    is_print_node(LastNodeId).

% is_print_node(+NodeId)
%
% Checks if a node is a `print` function call.
% - Succeeds if the node represents a call to the `print` function.
% - Fails otherwise.
%
is_print_node(NodeId) :-
    node(expr, NodeId, ExprProps, _),
    member(value:CallNodeId, ExprProps),
    node(call, CallNodeId, CallProps, _),
    member(func:FuncNodeId, CallProps),
    node(name, FuncNodeId, _, FuncAttrs),
    member(id:"print", FuncAttrs).

% is_print_node(+NodeId)
%
% Checks if a node is a control structure (if, for, while, try, orelse) that ends with a `print` statement.
% - Succeeds if the control structure ends with a `print` statement.
% - Fails otherwise.
%
is_print_node(NodeId) :-
    ( node(if, NodeId, IfProps, _), check_control(IfProps)
    ; node(for, NodeId, ForProps, _), check_control(ForProps)
    ; node(while, NodeId, WhileProps, _), check_control(WhileProps)
    ; node(try, NodeId, TryProps, _), check_control(TryProps)
    ; node(orelse, NodeId, OrelseProps, _), check_control(OrelseProps)
    ).

% check_control(+Props)
%
% Checks if a control structure (if, for, while, try, orelse) ends with a `print` statement.
% - Succeeds if the body or orelse part of the control structure ends with a `print` statement.
% - Fails otherwise.
%
check_control(Props) :-
    member(body:BodyNodes, Props),
    last(BodyNodes, LastNodeId),
    is_print_node(LastNodeId).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Infinite Loop Detection %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%
%% This implementation analyzes the condition of a while-loop to detect potential infinite loops. It works as follows:
%% 1. Condition Analysis:
%%   - If the condition is a constant True, the loop is infinite.
%%   - If the condition involves variables, their names are extracted.
%%   - If the condition is a comparison, all variables involved in the comparison are identified.
%% 2. Update Check:
%%   - The body of the loop is traversed to check if at least one variable from the condition is updated in a non-trivial way.
%%   - If no such update is found, the loop is considered infinite.
%% 3. Trivial Updates Handling:
%%   - Updates are considered trivial (and thus ignored) in three cases:
%%      1. A variable is assigned to itself (e.g., x = x).
%%      2. A variable is assigned a constant equal to its initial value.
%%      3. A variable is assigned another variable with the same initial value.
%%

% has_infinite_loops/0
%
% Checks if there is at least one infinite while-loop in the AST.
% - Succeeds (true) if any loop has an always-true condition or a variable never updated to false.
% - Fails (false) if no infinite loops are detected.
%
has_infinite_loops :-
    node(while, WhileId, _, _),
    is_infinite_loop(WhileId), !.

% display_infinite_loops/0
%
% Lists all while-loops that might be infinite.
% - Outputs the loop ID for each potential infinite loop.
% - If no infinite loops are found, prints a confirmation message.
% - Always succeeds after traversing the entire AST.
%
display_infinite_loops :-
    format('-----------------------------------------------------~n'),
    ( current_predicate(while1/1)
        ->  get_infinite_loops(InfiniteLoops),
            ( InfiniteLoops = []
                ->  format('No infinite while-loops found.~n', [])
                ;   format('Some while-loops are infinite.~n'),
                    forall(member(WhileId, InfiniteLoops), (
                        format('  - While loop (ID ~w) is infinite.~n', [WhileId])
                    ))
            )
        ;   format('No while-loops found (while1/1 not defined).~n')
    ),
    format('-----------------------------------------------------~n').

% get_infinite_loops(-InfiniteLoops)
%
% Retrieves all while-loops that might be infinite.
% - Returns a list of loop IDs for potential infinite loops.
% - Returns an empty list if no infinite loops are found.
%
get_infinite_loops(InfiniteLoops) :-
    findall(WhileId,
        (while1(WhileId),
            is_infinite_loop(WhileId)
        ),
        InfiniteLoops).


% is_infinite_loop(+WhileId)
%
% Succeeds if the while loop identified by WhileId is considered infinite.
% - WhileId: ID of the while-loop node to check.
% A loop is infinite if:
% - Its condition is always true, or
% - None of the variables in its condition are updated in a non-trivial way.
%
is_infinite_loop(WhileId) :-
    node(while, WhileId, Props, _),
    member(test:TestId, Props), % Get ID of condition node
    ( get_constant_value(TestId, true)  % Condition is simply True
    ;  ( condition_vars(TestId, Vars), % Get all the vars appearing in the condition
           Vars \= [],
           \+ update_exists(WhileId, Vars) % Check if at least one of the vars is updated non-trivially
       )
    ), !.

% condition_vars(+TestId, -Vars)
%
% Extracts the variable names used in the while loop's condition.
% - TestId: ID of the condition node to analyze.
% - Vars: List of variable names used in the condition.
%
condition_vars(TestId, Vars) :-
    ( node(compare, TestId, CompChildren, _)
        ->  findall(Var,
                ( member(Key, [left, right]),
                member(Key:Id, CompChildren),
                node(name, Id, _, Attrs),
                member(id:Var, Attrs)
                ),
                VarsList),
            list_to_set(VarsList, Vars)
        ; node(name, TestId, _, Attrs)
            ->  member(id:Var, Attrs),
                Vars = [Var]
            ;   Vars = []
    ).

% update_exists(+WhileId, +Vars)
%
% Succeeds if, within the body of the while loop, there exists an assignment
% (assign or augassign) that updates a variable in Vars in a non-trivial way.
% - WhileId: ID of the while-loop node to check.
% - Vars: List of variable names to check for updates.
%
update_exists(WhileId, Vars) :-
    node(while, WhileId, Props, _),
    member(body:BodyNodes, Props),
    update_in_nodes(BodyNodes, Vars).

% update_in_nodes(+Nodes, +Vars)
%
% Recursively traverses the list Nodes to find a non-trivial update.
% - Nodes: List of node IDs to traverse.
% - Vars: List of variable names to check for updates.
%
update_in_nodes([NodeId|Rest], Vars) :-
    ( ( node(assign, NodeId, AssignProps, _) ; node(augassign, NodeId, AssignProps, _) ),
      targets_updated(AssignProps, Vars)
    )
    ; ( node(_, NodeId, Props, _),
        member(SubKey, [body, orelse, handlers, test]),
        member(SubKey:SubNodes, Props),
        is_list(SubNodes),
        update_in_nodes(SubNodes, Vars)
      )
    ; update_in_nodes(Rest, Vars).
update_in_nodes([], _) :- fail.

% targets_updated(+AssignProps, +Vars)
%
% Succeeds if, in the list of assignment targets, one of them (named Var)
% belongs to Vars AND the update is non-trivial.
% - AssignProps: Properties of the assignment node.
% - Vars: List of variable names to check for updates.
%
targets_updated(AssignProps, Vars) :-
    member(targets:Targets, AssignProps),
    member(TargetId, Targets),
    node(name, TargetId, _, TargetAttrs),
    member(id:Var, TargetAttrs),
    member(Var, Vars),
    member(value:ValueId, AssignProps),
    \+ trivial_update(Var, ValueId).

% trivial_update(+Var, +ValueId)
%
% Succeeds if the update of Var is trivial, i.e.:
% 1. Assignment of the same variable (e.g., x = x)
% 2. Assignment of a constant identical to Var's initial value.
% 3. Assignment of another variable whose initial value is identical to Var's.
% - Var: Name of the variable being updated.
% - ValueId: ID of the value node being assigned to Var.
%
trivial_update(Var, ValueId) :-
    % Case 1: Self-assignment (x = x)
    (
       node(name, ValueId, _, ValAttrs),
       member(id:Var, ValAttrs)
    )
    % Case 2: Assignment of a constant equal to Var's initial value.
    ;   (
            ( node(constant, ValueId, _, Attrs) ; node(nameconstant, ValueId, _, Attrs) ),
            member(value:NewVal, Attrs),
            initial_value(Var, NewVal)
        )
    % Case 3: Assignment of another variable with the same initial value.
    ;   (
            node(name, ValueId, _, ValAttrs),
            member(id:OtherVar, ValAttrs),
            OtherVar \== Var,
            initial_value(Var, InitVal),
            initial_value(OtherVar, InitVal)
        ).

% initial_value(+Var, -Val)
%
% Extracts the initial constant value of Var.
% - Var: Name of the variable to check.
% - Val: Initial constant value of Var.
% Traverses the function body and takes the first assignment of Var.
%
initial_value(Var, Val) :-
    node(functiondef, _, FuncProps, _),
    member(body:BodyNodes, FuncProps),
    member(NodeId, BodyNodes),
    node(assign, NodeId, AssignProps, _),
    member(targets:Targets, AssignProps),
    member(TargetId, Targets),
    node(name, TargetId, _, Attrs),
    member(id:Var, Attrs),
    member(value:ValueId, AssignProps),
    get_constant_value(ValueId, Val),
    !.

% get_constant_value(+ValueId, -Val)
%
% Extracts the constant value from a constant or nameconstant node.
% - ValueId: ID of the value node to extract the constant from.
% - Val: Extracted constant value.
%
get_constant_value(ValueId, Val) :-
    ( node(constant, ValueId, _, Attrs) ; node(nameconstant, ValueId, _, Attrs) ),
    member(value:Val, Attrs).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Long Function Detection %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% has_too_long_functions/0
%
% Check if at least one function exceeds the maximum allowed length.
% - Succeeds (true) if any function contains more than 15 statements.
% - Fails (false) if no function is too long.
%
has_too_long_functions :-
    node(functiondef, FID, _, _),
    function_is_too_long(FID, _), !.

% display_too_long_functions/0
%
% Lists all functions that exceed the maximum allowed length.
% - Outputs the function name and ID for each violation.
% - If no functions are too long, prints a confirmation message.
% - Always succeeds after traversing the entire AST.
%
display_too_long_functions :-
    format('-----------------------------------------------------~n'),
    ( current_predicate(functiondef1/1)
        ->  get_too_long_functions(TooLongFunctions),
            ( TooLongFunctions = []
                ->  format('No functions exceed the maximum allowed length.~n', [])
                ;   format('Some functions exceed the maximum allowed length.~n'),
                    forall(member(Name-FID-NbStatement, TooLongFunctions), (
                        format('  - Function "~w" (ID ~w) has ~w statements.~n', [Name, FID, NbStatement])
                    ))
                )
        ;   format('No functions found (functiondef1/1 not defined).~n')
    ),
    format('-----------------------------------------------------~n').

% get_too_long_functions(-TooLongFunctions)
%
% Retrieves all functions that exceed the maximum allowed length.
% - Returns a list of `Name-FID-NbStatement` tuples for violating functions.
%   - `Name`: The name of the function.
%   - `FID`: The function's unique ID.
%   - `NbStatement`: The number of statements in the function.
% - Returns an empty list if no functions are too long.
%
get_too_long_functions(TooLongFunctions) :-
    findall(Name-FID-NbStatement,
        (node(functiondef, FID, _, Attrs),
            member(name:Name, Attrs),
            function_is_too_long(FID, NbStatement)
        ),
        TooLongFunctions
    ).

% function_is_too_long(+FunctionId, -NbStatement)
%
% Checks if a function exceeds the length limit.
% - FID: ID of the function node to check.
% - NbStatement: Unified with the number of statements of the function.
% - Succeeds if the function body contains more than 15 statements.
%
function_is_too_long(FID, NbStatement) :-
    node(functiondef, FID, Props, _),
    member(body:BodyNodes, Props),
    length(BodyNodes, NbStatement),
    NbStatement > 15,
    !.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Excessive Parameters %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% has_too_many_parameters/0
%
% Check if at least one function has too many parameters.
% - Succeeds (true) if any function has more than 5 parameters.
% - Fails (false) if no function exceeds the parameter limit.
%
has_too_many_parameters :-
    node(functiondef, FunctionId, _, _),
    function_has_too_many_parameters(FunctionId, _), !.

% display_too_many_parameters/0
%
% Lists all functions with too many parameters.
% - Outputs the function name and ID for each violation.
% - If no functions have too many parameters, prints a confirmation message.
% - Always succeeds after traversing the entire AST.
%
display_too_many_parameters :-
    format('-----------------------------------------------------~n'),
    ( current_predicate(functiondef1/1)
        ->  get_functions_with_too_many_parameters(FunctionsWithTooManyParameters),
            ( FunctionsWithTooManyParameters = []
                ->  format('No functions have too many parameters.~n', [])
                ;   format('Some functions have too many parameters.~n'),
                    forall(member(Name-FID-NbParam, FunctionsWithTooManyParameters), (
                        format('  - Function "~w" (ID ~w) has ~w parameters.~n', [Name, FID, NbParam])
                    ))
                )
        ;   format('No functions found (functiondef1/1 not defined).~n')
    ),
    format('-----------------------------------------------------~n').

% get_functions_with_too_many_parameters(-FunctionsWithTooManyParameters)
%
% Retrieves all functions that have too many parameters.
% - Returns a list of `Name-FID-NbParam` tuples for violating functions.
%   - `Name`: The name of the function.
%   - `FID`: The function's unique ID.
%   - `NbParam`: The number of parameters in the function.
% - Returns an empty list if no functions have too many parameters.
%
get_functions_with_too_many_parameters(FunctionsWithTooManyParameters) :-
    findall(Name-FID-NbParam,
        (node(functiondef, FID, _, Attrs),
            member(name:Name, Attrs),
            function_has_too_many_parameters(FID, NbParam)
        ),
        FunctionsWithTooManyParameters).

% function_has_too_many_parameters(+FID, -NbParam)
%
% Checks whether a function has too many parameters.
% - FID: ID of the function node to analyze.
% - NbParam:  Unified with the number of parameters of the function FID.
% - Succeeds if the function has more than 5 parameters.
%
function_has_too_many_parameters(FID, NbParam) :-
    node(functiondef, FID, Props, _),
    member(args:ArgsId, Props),
    node(arguments, ArgsId, ArgsProps, _),
    member(args:ArgIds, ArgsProps),
    length(ArgIds, NbParam),
    NbParam > 5,
    !.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Combined Pattern Checks %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% README %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%% This is the end of this parser !
%%% While the parser already covers a variety of
%%% common issues, there’s always room for improvement.
%%% 
%%% These two predicates below mixt all the others defined previously.
%%% - `check_all_patterns_respected.` will give you true
%%%      if there is no `bad pattern` in your source code.
%%% - `display_all_patterns_not_respected.` will give you
%%%      the feedback about all these `bad pattern` found in your source code.
%%%

% check_all_patterns_respected/0
%
% Verifies that all patterns are respected across the codebase.
% - Succeeds (true) if no violations are found for any pattern.
% - Fails (false) if any pattern violation is detected.
%
check_all_patterns_respected :-
    has_all_loop_have_used_vars,
    has_all_functions_have_return_as_last_statement,
    \+ has_too_many_parameters,
    \+ has_too_long_functions,
    \+ has_infinite_loops,
    \+ has_print_instead_return,
    \+ has_too_much_indent,
    \+ has_early_return,
    \+ has_incr_in_for_loops,
    \+ has_erase_args,
    \+ has_init_returns_object,
    \+ has_empty_init.

% display_all_patterns_not_respected/0
%
% Lists all violations of the defined patterns.
% - Outputs details for each violation, including function/loop names and IDs.
% - Always succeeds after traversing the entire AST.
%
display_all_patterns_not_respected :-
    display_functions_without_return_as_last_statement, format('~n'),
    display_all_unused_loop_vars, format('~n'),
    display_infinite_loops, format('~n'),
    display_incr_in_for_loops, format('~n'),
    display_too_many_parameters, format('~n'),
    display_too_long_functions, format('~n'),
    display_print_instead_return, format('~n'),
    display_too_much_indent, format('~n'),
    display_early_return, format('~n'),
    display_erase_args, format('~n'),
    display_init_returns_object, format('~n'),
    display_empty_init.