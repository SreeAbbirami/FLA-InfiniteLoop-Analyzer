/* CREATION OF THE FACTS FROM A JSON FILE REPRESENTING THE AST
  AS A NESTED DICTIONARY OF NODES AND SUBNODES */

:- use_module(library(http/json)).

% ==============================================================================

/* DATA STRUCTURES FOR THE FACTS */

%% node(NodeType, NodeId, ChildNodes, Values).
% Example: node(add, 4, [childlabel:Id | ListId], [valuesLabel:value]).
% Such node/4 facts will be generated dynamically while reading the json file.
:- dynamic node/4.

% ==============================================================================

load_python(File) :-
    retractall(node(_, _, _, _)),
    open(File, read, Stream),
    json_read_dict(Stream, Dict),
    close(Stream),
    create_facts(Dict).

load_and_save_python(File) :-
    load_python(File),
    findall(node(Type, Nid, Children, Vals), node(Type, Nid, Children, Vals), Nodes),
    open('facts.pl', write, Stream),
    maplist({Stream}/[Node] >> (print(Stream, Node), write(Stream, '.'), nl(Stream)), Nodes),
    close(Stream).

%% null_dict(+Dict)
% Create a dict with _type = null.
null_dict(Dict) :-
    Dict = _{ '_type': "Null"}.

%% is_null(+Dict, -Return_Dict)
% Check if the dict is null.
is_null(null, X) :- !, null_dict(X).
is_null(Dict, Dict).

%% is_null(+Dict)
% Check if the dict is null.
is_null(null).

/* UTILS FOR THE CREATION OF THE FACTS */

%% create_facts(+Dict)
% Start of the facts creation.
create_facts(Dict) :- create_facts(Dict, 0, _), !.

%% create_facts(+Dict, +Parent_Id, +Current_Id, -New_Id)
% 	Dict is a dict of the AST
% 	Type is a atom and represent the type of the node
% 	Parent_Id is the id of the parent
% 	Current_Id is the id of the current node
% 	New_Id is the id of the next node (replace the current_Id)
% Create facts for the given dictionary and type.

% IF Dict._type already represented by a rule
create_facts(Dict, C_Id, New_Id) :-
    dict_type_to_correct_atom(Dict, Type),
    findall(Key, get_dict(Key, Dict, _), Keys),
    categorize_dict(Dict, Keys, Children_Keys, Value_Keys),
    respect_rule(Dict, Children_Keys, Value_Keys, Children, Values),
    process_new_fact(Type, Children_Keys, Children, Value_Keys, Values, C_Id, New_Id).

%% dict_type_to_correct_atom(+Dict, -Type)
% 	Dict is a dict of the AST
% 	Type is a atom and represent the type of the node
% Get the type of the node from the dict.
% Transform it so it starts with a uppercase.
dict_type_to_correct_atom(Dict, Type) :-
    get_dict('_type', Dict, Type_To_Verify),
    string_lower(Type_To_Verify, Type_String),
    atom_string(Type, Type_String).

%% respect_rule(+Dict, +[Children_Keys], +[Value_Keys], -[Children], -[Values])
% =>
% respect_rule/3
%
% 	Dict is a dict of the AST
% 	[Children_Keys] is a list of keys of the dict
% 	[Value_Keys] is a list of final values of the current node
% 	[Children] is a list of dicts/lists of the children
% 	[Values] is a list of values of the current node
% Respect the rule for the given dict type.

% Launch the respect_rule with the 2 lists of keys (children and values)
respect_rule(Dict, Children_Keys, Value_Keys, Children, Values) :-
    respect_rule(Dict, Children_Keys, Children),
    respect_rule(Dict, Value_Keys, Values).

%% respect_rule(+Dict, +[Keys], -[Values])
% 	Dict is a dict of the AST
% 	[Keys] is a list of keys of the dict
% 	[Values] is a list of values of the keys in the dict
% For the given list of keys, get their values in the dict.

% IF the two lists are empty, return empty lists
respect_rule(_, [], []) :- !.

% ELSE IF the value is null, return null_dict and send it to the follow-up
respect_rule(Dict, [Key|T], [Value|T_V]) :-
    get_dict(Key, Dict, V),
    is_null(V),
    null_dict(Value),
    respect_rule(Dict, T, T_V).

% ELSE get the dict value and send it to the follow-up
respect_rule(Dict, [Key|T], [Value|T_V]) :-
    get_dict(Key, Dict, Value),
    respect_rule(Dict, T, T_V).

%% categorize_dict(+Dict, +[Keys], -[Children_Keys], -[Value_Keys])
% 	Dict is a dict of the AST
% 	[Keys] is a list of keys of the dict
% 	[Children_Keys] is a list of dicts/lists of the children
% 	[Value_Keys] is a list of final values of the current node
% Categorize the keys of the dict in 2 lists: children and values.

% IF the list of keys is empty, return empty lists
categorize_dict(_, [], [], []) :- !.

% ELSE IF the key is _type,
% send it to the follow-up
% (_type is the type of the node, not a child or a value)
categorize_dict(Dict, ['_type'|T], Children_Keys, Value_Keys) :-
    categorize_dict(Dict, T, Children_Keys, Value_Keys).

% ELSE IF the value is a dict or a list,
% it is a child,
% send it to the follow-up
categorize_dict(Dict, [K|T], [K|Children_Keys], Value_Keys) :-
    get_dict(K, Dict, Child),
    (is_dict(Child); is_list(Child)),
    categorize_dict(Dict, T, Children_Keys, Value_Keys).

% ELSE IF the value is null,
% it is a child,
% send it to the follow-up
categorize_dict(Dict, [K|T], [K|Children_Keys], Value_Keys) :-
    get_dict(K, Dict, Value),
    is_null(Value),
    categorize_dict(Dict, T, Children_Keys, Value_Keys).

% ELSE it is a value,
% send it to the follow-up
categorize_dict(Dict, [K|T], Children_Keys, [K|Value_Keys]) :-
    categorize_dict(Dict, T, Children_Keys, Value_Keys).

%% create_children_facts(+[Dicts], +Parent_Id, +Current_Id,
%                       -[Children_Ids], -New_Id)
% 	[Dicts] is a list of dicts of the AST (1 per child)
% 	Parent_Id is the id of the parent
% 	Current_Id is the id of the current node
% 	[Children_Ids] is the returned id(s) (1 per child)
% 	New_Id is the id of the next node (replace the Current_Id)
% For the list of children given, send it to the follow-up to create their facts.

% IF the list of dicts is empty, return empty lists
create_children_facts([], _, Id,
                        [], Id).

% ELSE IF the first element of the list of dicts is a list,
% send this list to the follow-up (it is a list of children)
% send the rest of the list of dicts to the follow-up
create_children_facts([Dict|Dicts], P_Id, C_Id,
                        [Id|Ids], R_id) :-
    is_list(Dict),
    create_children_facts(Dict, P_Id, C_Id,
                            Id, N_id),
    create_children_facts(Dicts, P_Id, N_id,
                            Ids, R_id).

% ELSE create the facts for the first element of the list of dicts
% send the rest of the list of dicts to the follow-up
create_children_facts([Dict|Dicts], P_Id, C_Id,
                        [C_Id|Ids], R_id) :-
    create_facts(Dict, C_Id, N_id),
    create_children_facts(Dicts, P_Id, N_id,
                            Ids, R_id).

%% merge_keys_and_val(+[Keys], +[Values], -[Keys_Values])
% 	[Keys] is a list of keys
% 	[Values] is a list of values
% 	[Keys_Values] is a list of keys and values in form of Key:Value
% Merge the keys and values in a list of Key:Value.

merge_keys_and_val([], [], []).
merge_keys_and_val([K|T_K], [V|T_V], [K:V|T]) :-
    merge_keys_and_val(T_K, T_V, T).

%% process_new_fact(+Type, +[Dicts_children], +[Values] +Parent_Id, +Current_Id,
%                       -New_Id)
% 	Type is the type of the fact
% 	[Dicts_children] is a list of dicts of the AST (1 per child)
% 	[Values] is a list of values of the current node
% 	Parent_Id is the id of the parent
% 	Current_Id is the id of the current node
% 	New_Id is the id of the next node (replace the current_Id)
% Given the list of dicts representing the children,
% create their facts and then add the current fact to the database.

process_new_fact(Type, Children_Keys, Dicts_children, Value_Keys, Values, C_Id, New_Id) :-
    %send to the children
    Children_id is C_Id + 1,
    create_children_facts(Dicts_children, C_Id, Children_id,
                            Children_Ids, New_Id),

    merge_keys_and_val(Children_Keys, Children_Ids, Children_Ids_With_Keys),
    merge_keys_and_val(Value_Keys, Values, Values_With_Keys),
    Val_Fact =.. [node, Type, C_Id, Children_Ids_With_Keys, Values_With_Keys],

    assertz(Val_Fact).

% ==============================================================================