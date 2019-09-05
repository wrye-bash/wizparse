// TODO Check that my statements *actually* don't have a return value in belt
// TODO newlines: skip or needed?
// TODO line continuations - can we skip?
// TODO Check if a Default statement can occur in the middle of Case statements
// TODO Check if multiple Default statements are allowed
// TODO See if there was any reason not to implement modulo
// TODO See if the use of fragments for keywords is OK or annoying in the interpreter
// TODO If lexing of strings breaks, consider using modes
// TODO Indexing / Splicing
grammar wizard;

/* ==== PARSER ==== */
/* === BASICS === */
// The main entry point.
// A body, followed by EOF.
runWiz: body EOF;

// A series of commands.
body: command*;

// A single line, can have a value or not.
command: stmt | expr;

/* === STATEMENTS === */
// A command without a return value. All statements can stand on
// their own.
stmt: assignment
      | compoundAssignment
      | controlFlowStmt
      | keywordStmt;

/* = ASSIGNMENT = */
// Just assigns a value to a variable.
assignment: IDENTIFIER ASSIGN expr;

// Compound assignments are statements of the form a x= b, where:
//   a is a variable
//   x is a mathematical operation
//   b is an expression
compoundAssignment: IDENTIFIER (ASSIGN_EXP
                               | ASSIGN_MUL
                               | ASSIGN_DIV
                               | ASSIGN_ADD
                               | ASSIGN_SUB) expr;

/* = CONTROL FLOW = */
// Statements that alter control flow.
controlFlowStmt: CANCEL
                 | forStmt
                 | ifStmt
                 | RETURN
                 | selectStmt
                 | whileStmt;

// Describes what do in a select statement if a certain case is hit.
caseBody: (BREAK | command)*;
caseStmt: CASE string caseBody;

// Describes what to do in a select statement if none of the cases are
// hit.
defaultStmt: DEFAULT caseBody;

// An elif statement, parsed like a regular if statement.
elifStmt: ELIF expr body;

// An else statement, parsed like an if statement without a guard
// expression.
elseStmt: ELSE body;

// A for loop. There are two possible types of for loop.
// Note that loopBody is used further down for whileStmt.
forStmt: FOR (forRangeLoop | forInLoop) END_FOR;
loopBody: (BREAK | CONTINUE | command)*;

// A for loop of the form 'For a from b to c [by d]', where:
//   a is a variable
//   b is the start value
//   c is the end value
//   d (optional) is the step size
forRangeLoop: IDENTIFIER FROM expr TO expr (BY expr)? loopBody;

// A for loop of the form 'For a in b', where:
//   a is a variable
//   b is a value to iterate over
forInLoop: IDENTIFIER IN expr loopBody;

// An if statement may have any number of elif statements, but at
// most one else statement.
ifStmt: IF expr body elifStmt* elseStmt? END_IF;

// There are two types of Select statement.
selectStmt: (selectOne | selectMany) END_SELECT;

// The two types differ only in their initial keyword.
// We copy their signature here to simplify the semantic analysis.
// Note that we check whether or not the selectCaseList is valid
// during semantic analysis.
selectCaseList: (caseStmt | defaultStmt)*;
optionTuple: string COMMA string COMMA string;
selectOne:  SELECT_ONE  string (COMMA optionTuple)* selectCaseList;
selectMany: SELECT_MANY string (COMMA optionTuple)* selectCaseList;

// A simple while loop. Runs until the guard is false.
whileStmt: WHILE expr loopBody END_WHILE;

/* = KEYWORD STATEMENTS = */
// A keyword statement is just a keyword followed by a
// comma-separated list of arguments.
// Note that argList is reused for functions later down.
argList: (expr (COMMA expr)*)?;
keywordStmt: KEYWORD argList;

/* === EXPRESSIONS === */
// A command with a return value.
// The order matters here - it specifies the operator precedence.
expr: LPAREN expr RPAREN
    // Function calls
    // May not actually return anything - we still parse them as
    // expressions for simplicity and check the return type when
    // doing semantic analysis.
    | expr DOT IDENTIFIER LPAREN argList RPAREN
    | IDENTIFIER LPAREN argList RPAREN
    // Logic operators, part 1
    | NOT expr
    // Indexing
    | expr LBRACKET expr RBRACKET
    // Slicing
    // Note that we check if this actually has at least one colon
    // during semantic analysis.
    | expr LBRACKET expr? COLON? expr? COLON? expr? RBRACKET
    // Mathematical operators
    | expr RAISE expr
    | expr (TIMES | DIVIDE) expr
    | expr (PLUS | MINUS) expr
    // Comparison operators
    | expr (GREATER | GREATER_OR_EQUAL) expr
    | expr (LESSER | LESSER_OR_EQUAL) expr
    | expr (EQUAL | NOT_EQUAL) expr
    // Logic operators, part 2
    | expr OR expr
    | expr AND expr
    // Direct values
    | (constant | literal | IDENTIFIER);

/* == NONEXECUTABLE EXPRESSIONS == */
// These are expressions that immediately resolve to a value,
// without any operation being involved.
// They cannot stand on their own, but we check this during semantic
// analysis.

/* = CONSTANTS = */
// One of the predefined constants for wizards.
constant: FALSE
          | TRUE
          | SUB_PACKAGES;

/* = LITERALS = */
// Only three types in this language - plus some 'pseudotypes' for
// list-like objects such as SubPackages.
literal: integer
         | decimal
         | string;

// Numbers - may be positive, negative or zero.
// Note that we keep these unnecessarily complex to simplify the
// semantic analysis.
integer: MINUS? DIGIT_SEQ;
decimal: MINUS? DIGIT_SEQ DOT DIGIT_SEQ;

// Strings - can use either "my string" or 'my string'. May also
// contain escape sequences.
string: STRING_DQUOTE | STRING_SQUOTE;

/* ==== LEXER ==== */
// Skip all comments.
COMMENT: ';' ~[\r\n]* -> skip;

// A line continuation - a backslash and a newline.
// We simply ignore them, eating the newline in the process. This
// simulates us appending the next line to the end of this one.
CONTINUATION: '\\' '\r'? '\n' -> skip;

// Common Operators
COMMA: ',';
DOT: '.';
LPAREN: '(';
RPAREN: ')';
LBRACKET: '[';
RBRACKET: ']';
COLON: ':';

// Assignment Operators
// Note that the compound assignment operators use the math
// operators defined below.
fragment EQ_SIGN: '=';
ASSIGN_ADD: EQ_SIGN PLUS;
ASSIGN_SUB: EQ_SIGN MINUS;
ASSIGN_MUL: EQ_SIGN TIMES;
ASSIGN_DIV: EQ_SIGN DIVIDE;
ASSIGN_EXP: EQ_SIGN RAISE;

// Comparison Operators
// Note that the order matters here - we want the LESSER_OR_EQUAL
// token filled first, if possible. Otherwise, the LESSER token
// would be matched even for legitimate cases where the
// LESSER_OR_EQUAL one needs to match.
fragment GT_SIGN: '>';
fragment LT_SIGN: '<';
fragment EXMARK: '!';
EQUAL: EQ_SIGN EQ_SIGN;
GREATER_OR_EQUAL: GT_SIGN EQ_SIGN;
GREATER: GT_SIGN;
LESSER_OR_EQUAL: LT_SIGN EQ_SIGN;
LESSER: LT_SIGN;
NOT_EQUAL: EXMARK EQ_SIGN;

// Special Case: need to define this last so it doesn't swallow all
// equals signs -> we want compound assignments and comparisons to
// process first.
ASSIGN: EQ_SIGN;

// Constants
TRUE:         'True';
FALSE:        'False';
SUB_PACKAGES: 'SubPackages';

// Control Flow Keywords
BREAK:       'Break';
CANCEL:      'Cancel';
CASE:        'Case';
CONTINUE:    'Continue';
DEFAULT:     'Default';
ELSE:        'Else';
ELIF:        'Elif';
END_IF:      'EndIf';
END_FOR:     'EndFor';
END_SELECT:  'EndSelect';
END_WHILE:   'EndWhile';
FOR:         'For';
IF:          'If';
RETURN:      'Return';
SELECT_ONE:  'SelectOne';
SELECT_MANY: 'SelectMany';
WHILE:       'While';

// Keywords
// Note the alternatives that are kept for backwards compatibility.
fragment DESELECT_ALL:         'DeSelectAll';
fragment DESELECT_ALL_PLUGINS: 'DeSelectAllPlugins' | 'DeSelectAllEspms';
fragment DESELECT_PLUGIN:      'DeSelectPlugin'     | 'DeSelectEspm';
fragment DESELECT_SUB_PACKAGE: 'DeSelectSubPackage';
fragment NOTE:                 'Note';
fragment RENAME_PLUGIN:        'RenamePlugin'       | 'RenameEspm';
fragment REQUIRE_VERSIONS:     'RequireVersions';
fragment RESET_PLUGIN_NAME:    'ResetPluginName'    | 'ResetEspmName';
fragment SELECT_ALL:           'SelectAll';
fragment SELECT_ALL_PLUGINS:   'SelectAllPlugins'   | 'SelectAllEspms';
fragment SELECT_PLUGIN:        'SelectPlugin'       | 'SelectEspm';
fragment SELECT_SUB_PACKAGE:   'SelectSubPackage';
KEYWORD: DESELECT_ALL
         | DESELECT_ALL_PLUGINS
         | DESELECT_PLUGIN
         | DESELECT_SUB_PACKAGE
         | NOTE
         | RENAME_PLUGIN
         | REQUIRE_VERSIONS
         | SELECT_ALL
         | SELECT_ALL_PLUGINS
         | SELECT_PLUGIN
         | SELECT_SUB_PACKAGE;

// Literals
// We need to be careful with the ESC here - we don't want to break
// our CONTINUATION token above.
fragment ESC: '\\' ~[\n\r];
DIGIT_SEQ: [0-9]+;
STRING_DQUOTE: '"' (ESC | ~[\\"])* '"';
STRING_SQUOTE: '\'' (ESC | ~[\\'])* '\'';

// Operators
AND:    '&' | 'and';
BY:     'by';
DIVIDE: '/';
FROM:   'from';
IN:     'in';
MINUS:  '-';
NOT:    '!' | 'not';
OR:     '|' | 'or';
PLUS:   '+';
RAISE:  '^';
TIMES:  '*';
TO:     'to';

// These rules need to pretty much come last, otherwise they would
// swallow up previous definitions.
// Identifiers - basically captures most leftovers.
IDENTIFIER: [A-Za-z_][A-Za-z0-9_]*;

// Ignore whitespace - at least for now, we might actually need this
// token though.
WHITESPACE: [ \n\r]+ -> skip;
