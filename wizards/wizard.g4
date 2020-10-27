// TODO See if the use of fragments for keywords is OK or annoying in semantic analysis
// TODO Check if the old parser allowed incrementing/decrementing anything and make that a breaking change

// Style guide:
//  - Parser rules are camelCase
//  - Lexer rules are PascalCase
//    - Exception: fragments and skips (i.e. ones that users will
//      _never_ see) are entirely uppercase.
//  - Wrap to 70 characters
//  - If a token has a single usage, move it up to its usage in the
//    parser. Saves a line. Exception is if the definition is long or
//    complex (e.g. Keyword).
grammar wizard;

/* ==== PARSER ==== */
/* === BASICS === */
// The main entry point.
// A body, followed by EOF.
parseWizard: body EOF;

// A series of commands.
body: (stmt | expr)*;

/* === STATEMENTS === */
// A command without a return value. All statements can stand on
// their own.
stmt: assignment
      | compoundAssignment
      | controlFlowStmt
      | keywordStmt;

/* = ASSIGNMENT = */
// Just assigns a value to a variable.
assignment: Identifier Assign expr;

// Compound assignments are statements of the form a x= b, where:
//   a is a variable
//   x is a mathematical operation
//   b is an expression
compoundAssignment: Identifier (CompoundExp
                               | CompoundMul
                               | CompoundDiv
                               | CompoundMod
                               | CompoundAdd
                               | CompoundSub) expr;

/* = CONTROL FLOW = */
// Statements that alter control flow.
controlFlowStmt: 'Break' # Break
                 | 'Cancel' # Cancel
                 | 'Continue' # Continue
                 | forStmt # For
                 | ifStmt # If
                 | 'Return' # Return
                 | selectStmt # Select
                 | whileStmt # While
                 ;

// Describes what do in a select statement if a certain case is hit.
// expr must be a string, type-check is during semantic analysis.
caseStmt: 'Case' expr body;

// Describes what to do in a select statement if none of the cases
// are hit.
defaultStmt: 'Default' body;

// An elif statement, parsed like a regular if statement.
elifStmt: 'Elif' expr body;

// An else statement, parsed like an if statement without a guard
// expression.
elseStmt: 'Else' body;

// A for loop. There are two possible types of for loop that differ
// only in their headers. They each begin with the keyword For,
// followed by an iteration variable a and then the header. Finally,
// a body and an EndFor keyword terminate the for loop.
forStmt: 'For' Identifier (forRangeHeader | forInHeader) body 'EndFor';

// The header of a for loop of the form 'For a from b to c [by d]',
// where:
//   a is the iteration variable, as specified in forStmt
//   b is the start value
//   c is the end value
//   d (optional) is the step size
forRangeHeader: 'from' expr 'to' expr ('by' expr)?;

// The header of a for loop of the form 'For a in b', where:
//   a is the iteration variable, as specified in forStmt
//   b is a value to iterate over
forInHeader: In expr;

// An if statement may have any number of elif statements, but at
// most one else statement.
ifStmt: 'If' expr body elifStmt* elseStmt? 'EndIf';

// There are two types of Select statement.
selectStmt: (selectOne | selectMany) 'EndSelect';

// The two types differ only in their initial keyword.
// We copy their signature here to simplify the semantic analysis.
// Note that we check whether or not the selectCaseList is valid
// and all these expr's resolve to strings during semantic analysis.
// A trailing comma is allowed here - it's simply ignored.
selectCaseList: (caseStmt | defaultStmt)*;
optionTuple: expr Comma expr Comma expr;
selectOne:  'SelectOne' expr (Comma optionTuple)* Comma? selectCaseList;
selectMany: 'SelectMany' expr (Comma optionTuple)* Comma? selectCaseList;

// A simple while loop. Runs until the guard is false.
whileStmt: 'While' expr body 'EndWhile';

/* = Keyword STATEMENTS = */
// A keyword statement is just a keyword followed by a
// comma-separated list of arguments.
// Note that argList is reused for functions later down.
argList: (expr (Comma expr)*)?;
keywordStmt: Keyword argList;

/* === EXPRESSIONS === */
// A command with a return value.
// The order matters here - it specifies the operator precedence.
expr: LeftParenthesis expr RightParenthesis # ParenExpr
    // Function calls
    // May not actually return anything - we still parse them as
    // expressions for simplicity and check the return type when
    // doing semantic analysis.
    | expr Dot Identifier LeftParenthesis argList RightParenthesis # DotFunctionCall
    | Identifier LeftParenthesis argList RightParenthesis # FunctionCall
    // Increment / Decrement
    // Note that, for backwards compatibility, postfix and prefix
    // should both return the new value.
    | Increment Identifier # PreIncrement
    | Identifier Increment # PostIncrement
    | Decrement Identifier # PreDecrement
    | Identifier Decrement # PostDecrement
    // Mathematical operators, part 1
    | Minus expr # Negative
    // Logic operators, part 1
    | ('!' | 'not') expr # Not
    // Indexing
    | expr LeftBracket expr RightBracket # Index
    // Slicing
    | expr LeftBracket expr? Colon expr? (Colon expr?)? RightBracket # Slice
    // Mathematical operators, part 2
    | expr Raise expr # Exponentiation
    | expr (Times | Divide | Modulo) expr # TimesDivideModulo
    | expr (Plus | Minus) expr # PlusMinus
    // Comparison operators
    // Colon present => case-insensitive
    | expr (Greater | GreaterOrEqual) Colon? expr # Greater
    | expr (Lesser | LesserOrEqual) Colon? expr # Lesser
    | expr (Equal | NotEqual) Colon? expr # Equal
    // Logic operators, part 2
    | expr ('|' | 'or') expr # Or
    | expr ('&' | 'and') expr # And
    // 'in' operator
    // Colon present => case-insensitive
    | expr In expr Colon? # In
    // Direct values
    // Constants, literals (three types) and variables
    | (constant | decimal | integer | string | Identifier) # Value
    ;

/* == NONEXECUTABLE EXPRESSIONS == */
// These are expressions that immediately resolve to a value,
// without any operation being involved.
// They cannot stand on their own, but we check this during semantic
// analysis.

/* = CONSTANTS = */
// One of the predefined constants for wizards.
constant: 'False' | 'True' | 'SubPackages';

/* = LITERALS = */
// Only three types in this language - plus some 'pseudotypes' for
// list-like objects such as SubPackages.
// Numbers - may be positive, negative or zero.
// Note that we keep these unnecessarily complex to simplify the
// semantic analysis.
integer: Number;
decimal: Number Dot Number;

// Strings - can use either "my string" or 'my string'. May also
// contain escape sequences.
string: DoubleQuotedString | SingleQuotedString;

/* ==== LEXER ==== */
// Skip all comments.
COMMENT: ';' ~[\r\n]* -> skip;

// A line continuation - a backslash and a newline.
// We simply ignore them, eating the newline in the process. This
// simulates us appending the next line to the end of this one.
// Note the [ \\\t]* section - eats up any backslashes and whitespace
// between the initial backslash and the newline. The old parser
// accepted those too, so we accept them for the sake of (relatively)
// painless backwards compatibility.
CONTINUATION: '\\' [ \\\t]* '\r'? '\n' -> skip;

// Common Operators
Comma: ',';
Dot: '.';
LeftParenthesis: '(';
RightParenthesis: ')';
LeftBracket: '[';
RightBracket: ']';
Colon: ':';

// Assignment Operators
// Note that the compound assignment operators use the math
// operators defined below.
fragment EQ_SIGN: '=';
CompoundAdd: Plus EQ_SIGN;
CompoundSub: Minus EQ_SIGN;
CompoundMul: Times EQ_SIGN;
CompoundDiv: Divide EQ_SIGN;
CompoundExp: Raise EQ_SIGN;
CompoundMod: Modulo EQ_SIGN;

// Comparison Operators
// Note that the order matters here - we want the LesserOrEqual
// token filled first, if possible. Otherwise, the Lesser token
// would be matched even for legitimate cases where the
// LesserOrEqual one needs to match.
fragment GT_SIGN: '>';
fragment LT_SIGN: '<';
fragment EXMARK: '!';
Equal: EQ_SIGN EQ_SIGN;
GreaterOrEqual: GT_SIGN EQ_SIGN;
Greater: GT_SIGN;
LesserOrEqual: LT_SIGN EQ_SIGN;
Lesser: LT_SIGN;
NotEqual: EXMARK EQ_SIGN;

// Special Case: need to define this last so it doesn't swallow all
// equals signs -> we want compound assignments and comparisons to
// process first.
Assign: EQ_SIGN;

// Control Flow Keywords
Break: 'Break';

// Keywords
// Note the alternatives that are kept for backwards compatibility.
Keyword: 'DeSelectAll'
         | 'DeSelectAllPlugins' | 'DeSelectAllEspms'
         | 'DeSelectPlugin'     | 'DeSelectEspm'
         | 'DeSelectSubPackage'
         | 'Note'
         | 'RenamePlugin'       | 'RenameEspm'
         | 'RequireVersions'
         | 'ResetPluginName'    | 'ResetEspmName'
         | 'SelectAll'
         | 'SelectAllPlugins'   | 'SelectAllEspms'
         | 'SelectPlugin'       | 'SelectEspm'
         | 'SelectSubPackage';

// Literals
fragment ESC: '\\' ~[\n\r];
Number: [0-9]+;
DoubleQuotedString: '"' (ESC | ~[\\"])* '"';
SingleQuotedString: '\'' (ESC | ~[\\'])* '\'';

// Mathematical Operators
Divide: '/';
Minus:  '-';
Plus:   '+';
Raise:  '^';
Times:  '*';
Modulo: '%';

// Misc Operators
Decrement: Minus Minus;
In: 'in';
Increment: Plus Plus;

// These rules need to pretty much come last, otherwise they would
// swallow up previous definitions.
// Identifiers - basically captures most leftovers.
Identifier: [A-Za-z_][A-Za-z0-9_]*;

// Ignore whitespace - at least for now, we might actually need this
// token though.
WHITESPACE: [ \t\n\r]+ -> skip;
