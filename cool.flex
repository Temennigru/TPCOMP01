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

char string_buf[MAX_STR_CONST + 1]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;
extern int comment_count;
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
COMMENTBEG      \(\*
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
ANYCHAR        .|\r

DARROW         =>
LE             <=
ASSIGN         <-



SYMBOL         [-+*/~<\(\){}@=\.,:;] { return yytext[0]; }


%%

 /*
  *  Nested comments
  *  Bool variable for comment mode
  */

<COMMENT>{COMMENTBEG}               { comment_count++; BEGIN(COMMENT); }
<INITIAL>{COMMENTBEG}               { comment_count++; BEGIN(COMMENT); }
<COMMENT>{COMMENTEND}               { comment_count--; if(comment_count == 0) { BEGIN(INITIAL); } }
<INITIAL>{COMMENTEND}               { cool_yylval.error_msg = "Unmatched *)\n"; return ERROR; }

 /*
 *<COMMENT><<EOF>>{
 *   BEGIN(INITIAL);
 *   cool_yylval.error_msg = "EOF in comment";
 *   return ERROR;
 *}
 */

<COMMENT>{ANYCHAR}                  { break; }


 /*
  *  The multiple-character operators.
  */

 /*
  *  Ignore these
  */

{ENDL}          { curr_lineno++; }

{WHITESPACE}    { break; }
{LINECOMMENT}   { curr_lineno++; break; }

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
<INITIAL>{TRUE}           { cool_yylval.boolean = true; return (BOOL_CONST); }
<INITIAL>{FALSE}          { cool_yylval.boolean = false; return (BOOL_CONST); }
<INITIAL>{DARROW}		  { return (DARROW); }
<INITIAL>{LE}             { return (LE); }
<INITIAL>{ASSIGN}         { return (ASSIGN); }
<INITIAL>{SYMBOL}         { return yytext[0]; }


 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */

<INITIAL>{TYPENAME}                  { cool_yylval.symbol = idtable.add_string(yytext); return TYPENAME; }
<INITIAL>{OBJECTNAME}                { cool_yylval.symbol = idtable.add_string(yytext); return OBJECTNAME; }

 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */

<INITIAL>{STRINGBEG}    { str_size = 0; BEGIN(STRING); }

<STRING>\x00 {
    BEGIN(STRING_NULL_ERR);
    break;
}

<STRING>\\\\0 {
    if (str_size >= MAX_STR_CONST) {
        BEGIN(STRING_OVERFLOW);
        break;
    } else {
        string_buf[str_size] = '\\'; string_buf[str_size] = '0'; str_size++;
    }
}

<STRING>\\0 {
    if (str_size >= MAX_STR_CONST) {
        BEGIN(STRING_OVERFLOW);
        break;
    } else {
        string_buf[str_size] = '\0';
        str_size++;
    }
}

<STRING>\\\\b {
    if (str_size >= MAX_STR_CONST) {
        BEGIN(STRING_OVERFLOW);
        break;
    } else {
        string_buf[str_size] = '\\'; string_buf[str_size] = 'b'; str_size++;
    }
}

<STRING>\\b {
    if (str_size >= MAX_STR_CONST) {
        BEGIN(STRING_OVERFLOW);
        break;
    } else {
        string_buf[str_size] = '\b';
        str_size++;
    }
}

<STRING>\\\\f {
    if (str_size >= MAX_STR_CONST) {
        BEGIN(STRING_OVERFLOW);
        break;
    } else {
        string_buf[str_size] = '\\';
        string_buf[str_size] = 'f';
        str_size++;
    }
}

<STRING>\\f {
    if (str_size >= MAX_STR_CONST) {
        BEGIN(STRING_OVERFLOW);
        break;
    } else {
        string_buf[str_size] = '\f';
        str_size++;
    }
}

<STRING>\\\\t {
    if (str_size >= MAX_STR_CONST) {
        BEGIN(STRING_OVERFLOW);
        break;
    } else {
        string_buf[str_size] = '\\';
        string_buf[str_size] = 't';
        str_size++;
    }
}

<STRING>\\t {
    if (str_size >= MAX_STR_CONST) {
        BEGIN(STRING_OVERFLOW);
        break;
    } else {
        string_buf[str_size] = '\t';
        str_size++;
    }
}

<STRING>\\\\n {
    if (str_size >= MAX_STR_CONST) {
        BEGIN(STRING_OVERFLOW);
        break;
    } else {
        string_buf[str_size] = '\\';
        string_buf[str_size] = 'n';
        str_size++;
    }
}

<STRING>\\n {
    if (str_size >= MAX_STR_CONST) {
        BEGIN(STRING_OVERFLOW);
        break;
    } else {
        string_buf[str_size] = '\n';
        str_size++;
    }
}

<STRING>\\\n {
    if (str_size >= MAX_STR_CONST) {
        BEGIN(STRING_OVERFLOW);
        break;
    } else {
        string_buf[str_size] = '\n';
        str_size++;
    }
}

<STRING>\\\" {
    if (str_size >= MAX_STR_CONST) {
        BEGIN(STRING_OVERFLOW);
        break;
    } else {
        string_buf[str_size] = '\"';
        str_size++;
    }
}

<STRING>\\\\ {
    if (str_size >= MAX_STR_CONST) {
        BEGIN(STRING_OVERFLOW);
        break;
    } else {
        string_buf[str_size] = '\\';
        str_size++;
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
        string_buf[str_size] = yytext[1];
        str_size++;
    }
}

<STRING>\\ { break; }

<STRING>{STRINGCHAR}+ {
    if (str_size >= MAX_STR_CONST) {
        BEGIN(STRING_OVERFLOW);
        break;
    } else {
        strcpy(&(string_buf[str_size]), yytext);
    }
}

<STRING>{STRINGEND} {
    BEGIN(INITIAL);
    string_buf[str_size] = '\0'
    str_size = 0;
    cool_yylval.symbol = stringtable.add_string(string_buf);
    return STR_CONST;
}

<STRING>\n {
    BEGIN(INITIAL);
    str_size = 0;
    cool_yylval.error_msg = "Unterminated string constant";
    return ERROR;
}

<STRING_OVERFLOW>{STRINGEND} {
    BEGIN(INITIAL);
    str_size = 0;
    cool_yylval.error_msg = "String constant too long";
    return ERROR;
}

<STRING_NULL_ERR>{STRINGEND} {
    BEGIN(INITIAL);
    str_size = 0;
    cool_yylval.error_msg = "String contains null character";
    return ERROR;
}

 /*
  *  Integer constant
  */

<INITIAL>{DIGIT}+       { cool_yylval.symbol = inttable.add_string(yytext); return INT_CONST; }

<STRING_OVERFLOW><<EOF>> {
    BEGIN(INITIAL);
    str_size = 0;
    cool_yylval.error_msg = "String constant too long";
    cool_yylval.error_msg = "EOF in string constant";
    return ERROR;
}

<STRING_NULL_ERR><<EOF>> {
    BEGIN(INITIAL);
    str_size = 0;
    cool_yylval.error_msg = "String contains null character";
    cool_yylval.error_msg = "Unexpected EOF";
    return ERROR;
}

<STRING><<EOF>> {
    BEGIN(INITIAL);
    str_size = 0;
    cool_yylval.error_msg = "EOF in string constant";
    return ERROR;
}


 /*
  *  If after all that it comes to this, somehting is wrong.
  */

.|\n {
    cool_yylval.error_msg = "Invalid character";
    return ERROR;
}

%%
