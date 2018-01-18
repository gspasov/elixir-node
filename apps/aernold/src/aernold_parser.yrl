Terminals
bool int contract id type 'if'
else func hex char string

%%Symbols
':' ';' '=' '+' '-' '*' '/' '{' '}'
'(' ')' '&&' '||' '>' '<' '==' '<='
'>=' '!=' ',' '!'
.

Nonterminals
File Contr Statement SimpleStatement CompoundStatement VariableDeclaration
VariableDefinition IfStatement ElseIfStatement ElseStatement Condition
FunctionDefinition FunctionParameters FunctionCall FunctionArguments Expression
Id Type Value OpCondition OpCompare Op
.

Rootsymbol File.

File -> Contr : '$1'.

Contr -> 'contract' id '{' Statement '}' : {contract, '$1', '$2', '$4'}.

Statement -> SimpleStatement ';' : '$1'.
Statement -> SimpleStatement ';' Statement : {'$1', '$3'}.
Statement -> CompoundStatement : '$1'.
Statement -> CompoundStatement  Statement : {'$1', '$2'}.
Statement -> Expression ';' : '$1'.
Statement -> Expression ';' Statement : {'$1', '$3'}.

SimpleStatement -> VariableDeclaration : '$1'.
SimpleStatement -> VariableDefinition : '$1'.

CompoundStatement -> IfStatement : '$1'.
CompoundStatement -> FunctionDefinition : '$1'.

VariableDeclaration -> Id ':' Type : {decl_var, '$1', '$3'}.
VariableDefinition -> Id ':' Type  '=' Expression : {def_var, '$1', '$3', '$5'}.

IfStatement -> 'if' '(' Condition ')' '{' Statement '}' : {if_statement, '$3', '$6'}.
IfStatement -> 'if' '(' Condition ')' '{' Statement '}' ElseStatement : {if_statement, '$3', '$6', '$8'}.
IfStatement -> 'if' '(' Condition ')' '{' Statement '}' ElseIfStatement : {if_statement, '$3', '$6', '$8'}.
ElseIfStatement -> 'else' 'if' '(' Condition ')' '{' Statement '}' : {if_statement, '$4', '$7'}.
ElseIfStatement -> 'else' 'if' '(' Condition ')' '{' Statement '}' ElseIfStatement : {if_statement, '$4', '$7', '$9'}.
ElseIfStatement -> 'else' 'if' '(' Condition ')' '{' Statement '}' ElseStatement : {if_statement, '$4', '$7', '$9'}.
ElseStatement -> 'else' '{' Statement '}' : {else_statement, '$3'}.

FunctionDefinition -> 'func' Id '(' FunctionParameters ')' '{' Statement '}' : {func_definition, '$2', '$4', '$7'}.

FunctionCall -> Id '(' ')' : {func_call, '$1'}.
FunctionCall -> Id '(' FunctionParameters ')' : {func_call, '$1', '$3'}.
FunctionCall -> Id '(' FunctionArguments ')' : {func_call, '$1', '$3'}.

FunctionParameters -> VariableDeclaration : {func_params, '$1'}.
FunctionParameters -> VariableDeclaration ',' FunctionParameters : {func_params, '$1', '$3'}.

FunctionArguments -> Expression : {func_args, '$1'}.
FunctionArguments -> Expression ',' FunctionArguments : {func_args, '$1', '$3'}.

Condition -> Expression : '$1'.
Condition -> Expression OpCondition Condition : {'$1', '$2', '$3'}.

Expression -> Value : '$1'.
Expression -> '!' Value : {'$1', '$2'}.
Expression -> Expression OpCompare Expression : {'$1', '$2', '$3'}.
Expression -> Expression Op Expression : {'$1', '$2', '$3'}.
Expression -> '(' Expression ')' : '$2'.
Expression -> '!' '(' Expression ')' : {'$1', '$3'}.
Expression -> '(' Expression ')' Expression : {'$1', '$3'}.
Expression -> '!' '(' Expression ')' Expression : {'$1', '$3', '$5'}.

Id -> id : {id, get_value('$1')}.
Type -> type : '$1'.

Value -> Id : '$1'.
Value -> FunctionCall : '$1'.
Value -> int : {int, get_value('$1')}.
Value -> bool : {bool, get_value('$1')}.
Value -> hex : {hex, get_value('$1')}.
Value -> char : {char, get_value('$1')}.
Value -> string : {string, get_value('$1')}.

OpCondition -> '&&' : '$1'.
OpCondition -> '||' : '$1'.

OpCompare -> '>' : '$1'.
OpCompare -> '<' : '$1'.
OpCompare -> '==' : '$1'.
OpCompare -> '<=' : '$1'.
OpCompare -> '>=' : '$1'.
OpCompare -> '!=' : '$1'.

Op -> '+' : '$1'.
Op -> '-' : '$1'.
Op -> '*' : '$1'.
Op -> '/' : '$1'.
Op -> '=' : '$1'.

Erlang code.

get_value({_, _, Value}) -> Value.