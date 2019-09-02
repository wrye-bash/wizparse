// TODO Check that my statements *actually* don't have a return value in belt
// TODO dot operator
// TODO Exec (shudder)
// TODO newlines: skip or needed?
// TODO line continuations - can we skip?
// TODO Check if a Default statement can occur in the middle of Case statements
// TODO Check if multiple Default statements are allowed
// TODO See if there was any reason not to implement modulo
// TODO See if the use of fragments for keywords is OK or annoying in the interpreter
grammar wizard;

/* ==== PARSER ==== */
/* == BASICS == */
// The main entry point.
// A body, followed by EOF.
file: body EOF;

// A series of commands.
body: command*;

// A single line, can have a value or not.
command: stmt | execExpr;

/* == HELPERS == */
// These are all just high-level aliases for strings to make the
// interpreter nicer.
description: STRING;
image:       STRING;
label:       STRING;
option:      STRING;

// These are all high-level aliases for TODO, see above.
// Note that I kept functionName flexible (as opposed to keyword,
// which is built into the lexer). This is to allow future expansion,
// namely user-defined functions.
functionName: TODO;
variable:     TODO;

// These are all high-level aliases for expr, see above.
forInTarget: expr;
forRangeStart: expr;
forRangeEnd:   expr;
forRangeStep:  expr;
guard: expr;

// Helper for Case statements. They are one of the two places where
// Break may occur.
caseBody:        caseBodyCommand*;
caseBodyCommand: breakStmt
                 | command;

// Helper for loops. They are the only places where Continue may
// occur and one of the two places where Break may occur.
loopBody:        loopBodyCommand*;
loopBodyCommand: breakStmt
                 | continueStmt
                 | command;

// Helper for Select statements. There may only be one Default
// statement, but it can be anywhere in the case list.
selectCaseList: caseStmt* defaultStmt caseStmt*;

// Helper for Select statements. An option tuple is a comma-separated
// list of three strings used to describe the options that will be
// shown in the installer.
optionTuple: option COMMA description COMMA image;

// Helper for function calls and keyword statements.
// Matches an entire argument list, including correct commas and, in
// the case of functionArgList, parantheses.
argList: (expr (COMMA expr)*)?;
keywordArgList: argList;
functionArgList: LPAREN argList RPAREN;

/* == STATEMENTS == */
// A command without a return value. All statements can stand on
// their own.
stmt: assignment
      | compoundAssignment
      | controlFlowStmt
      | functionCallStmt
      | keywordStmt;

/* = ASSIGNMENT = */
// Just assigns a value to a variable.
assignment: variable EQUALS expr;

// Compound assignments are statements of the form a x= b, where:
//   a is a variable
//   x is a MATH_OPERATOR (see lexer definition)
//   b is an expression
// Note that we do this in such a redundant way to simplify the
// interpreter later on.
compoundAssignment:     compoundAddition
                        | compoundSubtraction
                        | compoundMultiplication
                        | compoundDivision
                        | compoundExponentiation;
compoundAddition:       variable PLUS   EQUALS expr;
compoundSubtraction:    variable MINUS  EQUALS expr;
compoundMultiplication: variable TIMES  EQUALS expr;
compoundDivision:       variable DIVIDE EQUALS expr;
compoundExponentiation: variable RAISE  EQUALS expr;

/* = CONTROL FLOW = */
// Statements that alter control flow.
// Note that we put a level of abstraction over the tokens here
// because we need to visit these as nodes later for the interpreter.
controlFlowStmt: cancelStmt
                 | forStmt
                 | ifStmt
                 | returnStmt
                 | selectStmt
                 | whileStmt;

// Breaks out of a loop or select statement.
breakStmt: BREAK;

// Cancels the entire wizard and shows an appropriate window.
cancelStmt: CANCEL;

// Describes what do in a select statement if a certain case is hit.
caseStmt: CASE label caseBody;

// Ends the current iteration of a loop and moves on to the next one,
// if possible.
continueStmt: CONTINUE;

// Describes what to do in a select statement if none of the cases are
// hit.
defaultStmt: DEFAULT caseBody;

// An elif statement, parsed like a regular if statement.
elifStmt: ELIF guard body;

// An else statement, parsed like an if statement without a guard
// expression.
elseStmt: ELSE body;

// A for loop. There are two possible types of for loop.
forStmt: FOR (forRangeLoop | forInLoop) END_FOR;

// A for loop of the form 'For a from b to c [by d]', where:
//   a is a variable
//   b is the start value
//   c is the end value
//   d (optional) is the step size
forRangeLoop:  variable FROM forRangeStart TO forRangeEnd (BY forRangeStep)? loopBody;

// A for loop of the form 'For a in b', where:
//   a is a variable
//   b is a value to iterate over
forInLoop:   variable IN forInTarget loopBody;

// An if statement may have any number of elif statements, but at
// most one else statement.
ifStmt: IF guard body elifStmt* elseStmt? END_IF;

// Finishes the entire wizard and shows a results page.
returnStmt: RETURN;

// There are two types of Select statement.
selectStmt: (selectOne | selectMany) END_SELECT;

// The two types differ only in their initial keyword.
// We copy their signature here to simplify the interpreter.
selectOne:  SELECT_ONE  description (COMMA optionTuple)* selectCaseList;
selectMany: SELECT_MANY description (COMMA optionTuple)* selectCaseList;

// A simple while loop. Runs until the guard is false.
whileStmt: WHILE guard loopBody END_WHILE;

/* = FUNCTION CALLS = */
// A function call can either be a dot function or a regular one.
functionCallStmt: dotFunctionCallStmt | regularFunctionCallStmt;

// A dot function call: a.b(...), behaves like b(a, ...).
dotFunctionCallStmt: expr DOT functionName functionArgList;

// A regular function call with function name and arguments.
regularFunctionCallStmt: functionName functionArgList;

/* = KEYWORD STATEMENTS = */
// A keyword statement is just a keyword followed by a
// comma-separated list of arguments.
keywordStmt: KEYWORD keywordArgList;

/* == EXPRESSIONS == */
// A command with a return value.
expr: execExpr | nonexecExpr;

// An expression that can stand on its own.
execExpr: boolOp
          | comparison
          | decrement
          | increment
          | mathOp;

// An expression that cannot stand on its own.
nonexecExpr: constant
             | literal
             | variable;

/* ==== LEXER ==== */
// Skip all comments.
COMMENT: ';' ~[\r\n]* -> skip;

// Matches both Windows-style and Unix-style newlines.
NEWLINE: '\r'? '\n';

// A line continuation - a backslash and a newline.
CONTINUATION: '\\' NEWLINE -> skip;

// Comparison Operators
EQUALS: '=';

// Constants
TRUE:        'True';
FALSE:       'False';
SUBPACKAGES: 'SubPackages';

// Control Flow Keywords
BREAK:       'Break';
BY:          'by';
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
FROM:        'from';
IF:          'If';
IN:          'in';
RETURN:      'Return';
SELECT_ONE:  'SelectOne';
SELECT_MANY: 'SelectMany';
TO:          'to';
WHILE:       'While';

// Function Call Operators
// COMMA is also used for Select statements.
COMMA: ',';
DOT: '.';
LPAREN: '(';
RPAREN: ')';

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

// Math Operators
PLUS:   '+';
MINUS:  '-';
TIMES:  '*';
DIVIDE: '/';
RAISE:  '^';
