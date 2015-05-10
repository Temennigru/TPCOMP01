/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;
extern int comment_count;
extern bool is_comment;
extern int str_size;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */

%}

/*
 *  Start conditions
 */

%x STRING STRING_OVERFLOW STRING_NULL_ERR COMMENT

/*
 * Define names for regular expressions here.
 */

DIGIT           [0-9]
WHITESPACE      [ \n\f\r\t\v]
ENDL            \n
LINECOMMENT     --[^\n]*
COMMENTBEGIN    \(\*
COMMENTEND      \*\)
STRINGBEG       \"
STRINGEND       \"
STRINGCHAR     [^\"\0\n\\]
TYPENAME       [A-Z][A-z0-9_]
OBJECTNAME     [a-z][A-z0-9_]
CLASS          [Cc][Ll][Aa][Ss][Ss]
ELSE           [Ee][Ll][Ss][Ee]
IF             [Ii][Ff]
FI             [Ff][Ii]
IN             [Ii][Nn]
INHERITS       [Ii][Nn][Hh][Ee][Rr][Ii][Tt][Ss]
ISVOID         [Ii][Ss][Vv][Oo][Ii][Dd]
LET            [Ll][Ee][Tt]
LOOP           [Ll][Oo][Oo][Pp]
POOL           [Pp][Oo][Oo][Ll]
THEN           [Tt][Hh][Ee][Nn]
WHILE          [Ww][Hh][Ii][Ll][Ee]
CASE           [Cc][Aa][Ss][Ee]
ESAC           [Ee][Ss][Aa][Cc]
NEW            [Nn][Ee][Ww]
OF             [Oo][Ff]
NOT            [Nn][Oo][Tt]
TRUE           t[Rr][Uu][Ee]
FALSE          f[Aa][Ll][Ss][Ee]
AT             @
ANYCHAR        .|\r

DARROW         =>
MULT           \*
DOT            \.
SEMI           ;
DIV            \/
PLUS           \+

MINUS          -
NEG            ~
LPAREN         \(
RPAREN         \)
LT             \<
LE             <=
COMMA          ,
EQ             =
ASSIGN         <-
COLON          \:
LBRACE         \{
RBRACE         \}
%%

 /*
  *  Nested comments
  *  Bool variable for comment mode
  */

<INITIAL, COMMENT>COMMENTBEGIN    { comment_count++; is_comment = true; }
<COMMENT>         COMMENTEND      { comment_count--; if(comment_count == 0) { is_comment = false; } }


 /*
  *  The multiple-character operators.
  */


/* ignore these */
{WHITESPACE}    { break; }
{ANYCHAR}       { break; }
{LINECOMMENT}   { curr_lineno++; break; }

{ENDL}          { curr_lineno++; }

<INITIAL>{CLASS}          { return (CLASS); }
<INITIAL>{ELSE}           { return (ELSE); }
<INITIAL>{IF}             { return (IF); }
<INITIAL>{FI}             { return (FI); }
<INITIAL>{IN}             { return (IN); }
<INITIAL>{INHERITS}       { return (INHERITS); }
<INITIAL>{ISVOID}         { return (ISVOID); }
<INITIAL>{LET}            { return (LET); }
<INITIAL>{LOOP}           { return (LOOP); }
<INITIAL>{POOL}           { return (POOL); }
<INITIAL>{THEN}           { return (THEN); }
<INITIAL>{WHILE}          { return (WHILE); }
<INITIAL>{CASE}           { return (CASE); }
<INITIAL>{ESAC}           { return (ESAC); }
<INITIAL>{NEW}            { return (NEW); }
<INITIAL>{OF}             { return (OF); }

<INITIAL>{NOT}            { return (NOT); }
<INITIAL>{TRUE}           { return (TRUE); }
<INITIAL>{FALSE}          { return (FALSE); }
<INITIAL>{AT}             { return (AT); }
<INITIAL>{DARROW}		      { return (DARROW); }
<INITIAL>{MULT}           { return (MULT); }
<INITIAL>{DOT}            { return (DOT); }
<INITIAL>{SEMI}           { return (SEMI); }
<INITIAL>{DIV}            { return (DIV); }

<INITIAL>{PLUS}           { return (PLUS); }
<INITIAL>{MINUS}          { return (MINUS); }
<INITIAL>{NEG}            { return (NEG); }
<INITIAL>{LPAREN}         { return (LPAREN); }
<INITIAL>{RPAREN}         { return (RPAREN); }
<INITIAL>{LT}             { return (LT); }
<INITIAL>{LE}             { return (LE); }
<INITIAL>{COMMA}          { return (COMMA); }
<INITIAL>{EQ}             { return (EQ); }
<INITIAL>{ASSIGN}         { return (ASSIGN); }
<INITIAL>{COLON}          { return (COLON); }
<INITIAL>{LBRACE}         { return (LBRACE); }
<INITIAL>{RBRACE}         { return (RBRACE); }


 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */

<YYINITIAL>{TYPEID}                  { cool_yylval.cValue = strdup(yytext); return TYPEID; }
<YYINITIAL>{OBJECTID}                { cool_yylval.cValue = strdup(yytext); return OBJECT; }

 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */

<INITIAL>{STRINGBEGIN}    { str_size = 0; BEGIN(STRING); }

<STRING>\x00 {
    BEGIN(STRING_NULL_ERR);
    break;
}
<STRING>\\\\b {
    if (str_size >= MAX_STR_CONST) {
        BEGIN(STRING_OVERFLOW);
        break;
    } else {
        string_buf[str_size] = '\\'; string_buf[str_size] = 'b'); str_size++;
    }
}
<STRING>\\b {
    if (str_size >= MAX_STR_CONST) {
        BEGIN(STRING_OVERFLOW);
        break;
    } else {
        string_buf[str_size] = '\b');
        str_size++;
    }
}
<STRING>\\\\f {
    if (str_size >= MAX_STR_CONST) {
        BEGIN(STRING_OVERFLOW);
        break;
    } else {
        string_buf[str_size] = '\\';
        string_buf[str_size] = 'f');
        str_size++;
    }
}
<STRING>\\f {
    if (str_size >= MAX_STR_CONST) {
        BEGIN(STRING_OVERFLOW);
        break;
    } else {
        string_buf[str_size] = '\f');
        str_size++;
    }
}
<STRING>\\\\t {
    if (str_size >= MAX_STR_CONST) {
        BEGIN(STRING_OVERFLOW);
        break;
    } else {
        string_buf[str_size] = '\\';
        string_buf[str_size] = 't');
        str_size++;
    }
}
<STRING>\\t {
    if (str_size >= MAX_STR_CONST) {
        BEGIN(STRING_OVERFLOW);
        break;
    } else {
        string_buf[str_size] = '\t');
        str_size++;
    }
}
<STRING>\\\\n {
    if (str_size >= MAX_STR_CONST) {
        BEGIN(STRING_OVERFLOW);
        break;
    } else {
        string_buf[str_size] = '\\';
        string_buf[str_size] = 'n');
        str_size++;
    }
}
<STRING>\\n {
    if (str_size >= MAX_STR_CONST) {
        BEGIN(STRING_OVERFLOW);
        break;
    } else {
        string_buf[str_size] = '\n');
        str_size++;
    }
}

<STRING>\\\n {
    if (str_size >= MAX_STR_CONST) {
        BEGIN(STRING_OVERFLOW);
        break;
    } else {
        string_buf[str_size] = '\n');
        str_size++;
    }
}

<STRING>\\\" {
    if (str_size >= MAX_STR_CONST) {
        BEGIN(STRING_OVERFLOW);
        break;
    } else {
        string_buf[str_size] = '\"');
        str_size++;
    }
}

<STRING>\\\\ {
    if (str_size >= MAX_STR_CONST) {
        BEGIN(STRING_OVERFLOW);
        break;
    } else {
        string_buf[str_size] = '\\');
        str_size++;
    }
}

<STRING>\\                { ; }

<STRING>{STRINGCHAR}+ {
    if (str_size >= MAX_STR_CONST) {
        BEGIN(STRING_OVERFLOW);
        break;
    } else {
        strcpy(&(string_buf[str_size]), yytext);
    }
}

/*
 *  Escaped regular characters
 */

<STRING>\\{STRINGCHAR} {
    if (str_size >= MAX_STR_CONST) {
        BEGIN(STRING_OVERFLOW);
        break;
    } else {
        /* Append character after '\\' */
        string_buf[str_size] = yytext[1]);
        str_size++;
    }
}

<STRING>{STRINGEND} {
    BEGIN(YYINITIAL);
    String s = string_buf.toString();
    return STRINGEND;
}

<STRING>\n {
    string_buf.setLength(0);
    BEGIN(YYINITIAL);
    fprintf(stderr, "ERROR: Unterminated string constant\n");
    return ERROR;
}

<STRING_OVERFLOW>{STRINGEND} {
    BEGIN(INITIAL);
    fprintf(stderr, "ERROR: String constant too long\n");
    return ERROR;
}

<STRING_NULL_ERR>{STRINGEND} {
    BEGIN(INITIAL);
    fprintf(stderr, "ERROR: String contains null character\n");
    return ERROR;
}

/*
 *  Integer constant
 */

<YYINITIAL>{DIGIT}+       { cool_yylval.iValue=atoi(yytext); return INT_CONST; }

/*
 *  If after all that it comes to this, somehting is wrong.
 */

.|\n {
    fprintf(stderr, "ERROR: Invalid character\n");
    return ERROR;
}
%%