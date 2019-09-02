// TODO Check that my statements *actually* don't have a return value in belt
// TODO Check if there even are any non-exec statements
// TODO dot operator
// TODO Exec (shudder)
// TODO newlines: skip or needed?
// TODO line continuations - can we skip?
grammar wizard;

/* ==== PARSER ==== */
/* == BASICS == */
// The main entry point.
// Any number of commands, separated by newlines.
file: command* EOF;

// A single line, can have a value or not.
command: execStmt | execExpr;

/* == STATEMENTS == */
// A command without a return value.
stmt: execStmt | nonexecStmt;

// A statement that can stand on its own.
execStmt: assignment
          | compoundAssignment
          | controlFlowStmt
          | functionCall
          | keywordCall;

// Just assigns a value to a variable.
assignment: variable EQUALS expr;

// Compound assignments are statements of the form a x= b, where:
//   a is a variable
//   x is a MATH_OPERATOR (see lexer definition)
//   b is an expression
compoundAssignment: compoundAddition
                    | compound_subtraction
                    | compound_multiplication
                    | compound_division
                    | compound_exponentiation;
compoundAddition:       variable PLUS   EQUALS expr;
compoundSubtraction:    variable MINUS  EQUALS expr;
compoundMultiplication: variable TIMES  EQUALS expr;
compoundDivision:       variable DIVIDE EQUALS expr;
compoundExponentiation: variable RAISE  EQUALS expr;

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
caseStmt: CASE label line*;

// Ends the current iteration of a loop and moves on to the next one,
// if possible.
continueStmt: CONTINUE;

// Describes what to do in a select statement if none of the cases are
// hit.
defaultStmt: DEFAULT line*;

// Helpers for loops. They are the only places where Continue may
// occur and one of the two places where Break may occur.
loopBody: loopBodyLine*;
loopBodyLine: breakStmt | continueStmt | command;

// A for loop. There are two possible types of for loop.
forStmt: FOR (forRangeLoop | forInLoop) END_FOR;

// A for loop of the form 'For a from b to c [by d]', where:
//   a is a variable
//   b is the start value
//   c is the end value
//   d (optional) is the step size
forRangeLooop: variable FROM forRangeStart TO forRangeEnd (BY forRangeStep)? loopBody;
forRangeStart: expr;
forRangeEnd: expr;
forRangeStep: expr;

// A for loop of the form 'For a in b', where:
//   a is a variable
//   b is a value to iterate over
forInLoop: variable IN forInTarget loopBody;
forInTarget: expr;

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

// Constants
TRUE:        'True'
FALSE:       'False'
SUBPACKAGES: 'SubPackages'

// Keywords, used mainly for control flow statements
BREAK:       'Break';
BY:          'by';
CANCEL:      'Cancel';
CASE:        'Case';
CONTINUE:    'Continue';
DEFAULT:     'Default';
ELSE:        'Else';
ELIF:        'Elif';
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

// Used for assignments and comparisons.
EQUALS: '=';

// Math Operators
PLUS:   '+';
MINUS:  '-';
TIMES:  '*';
DIVIDE: '/';
RAISE:  '^';

// Matches both Windows-style and Unix-style newlines.
NEWLINE: '\r'? '\n';
