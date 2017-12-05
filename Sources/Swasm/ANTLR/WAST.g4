grammar WAST;

// Lexical Format
// https://webassembly.github.io/spec/text/lexical.html

// Tokens

Keyword : [a-z] IDCharacter*;

// White Space

Space : (' ' | Format | Comment)+ -> skip;
fragment Format : [\u0009\u000A\u000D];

// Comments

Comment : LineComment | BlockComment;

fragment LineComment : ';;' LineChar* ('\u000A' | EOF);
fragment LineChar : ~'\u000A';

fragment BlockComment : '(;' BlockChar* ';)';
fragment BlockChar : ~[(;]
                   | BlockComment
                   ;

// Values
// https://webassembly.github.io/spec/text/values.html

// Integers

fragment Sign : | '+' | '-';
fragment Digit : [0-9];

fragment HexDigit : Digit | [a-fA-F];

// fragment Number : Digit
//                 | Num '_'? Digit;
fragment Number : Digit NumTail?;
fragment NumTail : | '_' NumTail;

// fragment HexNumber : HexDigit
//                    | HexNum '_'? HexDigit;
fragment HexNumber : HexDigit HexNumTail?;
fragment HexNumTail : | '_' HexNumTail;

UnsignedN : Number
          | '0x' HexNumber
          ;

SignedN : Sign Number
        | Sign '0x' HexNumber
        ;

Integer : UnsignedN | SignedN;

// Floating-Point

fragment Frac :
              | Digit Frac
              | Digit '_' Digit Frac
              ;

fragment HexFrac :
                 | HexDigit HexFrac
                 | HexDigit '_' HexDigit HexFrac
                 ;

fragment Float : Number '.' Frac
               | Number ('E' | 'e') Sign Number
               | Number '.' Frac ('E' | 'e') Sign Number
               ;

fragment HexFloat : HexNumber '.' HexFrac
                  | HexNumber ('E' | 'e') Sign HexNumber
                  | HexNumber '.' HexFrac ('E' | 'e') Sign HexNumber
                  ;

Fn : Sign FnMag;
fragment FnMag : Float
               | HexFloat
               | 'inf'
               | 'nan'
               | 'nan:0x' HexNumber
               ;

// String

String : '"' StringElem '"';
fragment StringElem : StringChar
                    | '\\' HexDigit HexDigit
                    ;

fragment StringChar : ~[\u0000-\u0020\u007F"\\]
                    | '\t'
                    | '\n'
                    | '\r'
                    | '"'
                    | '\''
                    | '\\'
                    | '\\u{' HexNumber '}'
                    ;

// Names

name : String;

// Identifiers

id : ID;
ID : '$' IDCharacter+;
IDCharacter : [0-9a-zA-Z!#$%&′*+-./:<=>?@\\^_`~];

// Types
// https://webassembly.github.io/spec/text/types.html

// Value Types

valueType : 'i32'
          | 'i64'
          | 'f32'
          | 'f64'
          ;

// Result Types

resultType : functionResult?;

// Function Types

functionType : '(' 'func' functionParameter* functionResult* ')';
functionParameter : '(' 'param' id? valueType* ')';
functionResult : '(' 'result' valueType* ')';

// Limits

limits : UnsignedN
       | UnsignedN UnsignedN;

// Memory Types

memoryType : limits;

// Table Types

tableType : limits elemtype;
elemtype : 'anyfunc';

// Global Types

globalType : valueType
           | '(' 'mut' valueType ')'
           ;

// Instructions
// https://webassembly.github.io/spec/text/instructions.html

instruction : plainInstruction
            | blockInstruction
            ;

// Labels

label : id
      |
      ;

blockInstruction : 'block' label resultType instruction* 'end' id?
                 | 'loop' label resultType instruction* 'end' id?
                 | 'if' label resultType instruction* 'else' id? instruction* 'end' id?
                 ;

plainInstruction : 'unreachable'
                 | 'nop'
                 | 'br' labelIndex
                 | 'br_if'
                 | 'br_table'
                 | 'return'
                 | 'call' functionIndex
                 | 'call_indirect' typeIndex
                 ;

expression : '(' instruction* ')'
           |
           ;

// Modules
// https://webassembly.github.io/spec/text/modules.html

// Indices

typeIndex : UnsignedN | id;
functionIndex : UnsignedN | id;
tableIndex : UnsignedN | id;
memoryIndex : UnsignedN | id;
globalIndex : UnsignedN | id;
localIndex : UnsignedN | id;
labelIndex : UnsignedN | id;

// Types

typeDefinition : '(' 'type' id? functionType ')';

// Type Uses

typeUse : '(' 'type' typeIndex ')'
        | '(' 'type' typeIndex ')' functionParameter* functionResult*
        | functionParameter* functionResult*
        ;

// Imports

importDefinition : '(' 'import' name name importDescriptor ')';
importDescriptor : '(' 'func' id? typeUse ')'
                 | '(' 'table' id? tableType ')'
                 | '(' 'memory' id? memoryType ')'
                 | '(' 'global' id? globalType ')'
                 ;

// Functions

functionDefinition : '(' 'func' id? typeUse localDefinition* expression ')'
                   | '(' 'func' id? '(' 'export' name ')' typeUse localDefinition* expression ')';
localDefinition : '(' 'local' id? valueType ')';

// Tables

tableDefinition : '(' 'table' id? tableType ')';

// Memories

memoryDefinition : '(' 'memory' id? memoryType ')';

// Globals

globalDefinition : '(' 'global' id? globalType expression ')';

// Exports

exportDefinition : '(' 'export' name exportDescriptor ')';
exportDescriptor : '(' 'func' functionIndex ')'
                 | '(' 'table' tableIndex ')'
                 | '(' 'memory' memoryIndex ')'
                 | '(' 'global' globalIndex ')'
                 ;

// Start Function

startFunction : '(' 'start' functionIndex ')';

// Element Segments

elementSegment : '(' 'elem' tableIndex '(' 'offset' expression ')' functionIndex* ')';

// Data Segments

dataSegment : '(' 'data' memoryIndex '(' 'offset' expression ')' dataString ')';
dataString : String*;

// Modules

module : '(' 'module' id? moduleField* ')';
moduleField : typeDefinition
            | importDefinition
            | functionDefinition
            | tableDefinition
            | memoryDefinition
            | globalDefinition
            | exportDefinition
            | startFunction
            | elementSegment
            | dataSegment
            ;
