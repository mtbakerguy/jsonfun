%{
#include <math.h>
#include <errno.h>
#include "JSON.h"
#include "y.tab.h"

using namespace std;

extern "C" void yyerror(const char*);
extern "C" int yylex(void);
extern "C" void spit(const char*);
extern __thread ParserState* ps;

void
yyerror(const char* s) {
    cerr << s << ":  line(" << ps->lineno << ")" << endl;
    exit(EXIT_FAILURE); 
}

void spit(const char* d) { cout << d << endl; }
%}

%option noyywrap
ws [ \t\n\r]+
%%
"[" {
    ps->objects.push_back(new JSONBeginArray);
    ps->composites.push(new JSON);
    return T_BEGIN_ARRAY;
}
"]" {
    ps->objects.push_back(new JSONEndArray);
    return T_END_ARRAY;
}
"{" {
    ps->objects.push_back(new JSONBeginObject); 
    ps->composites.push(new JSON);
    return T_BEGIN_OBJECT;
}
"}" {
    ps->objects.push_back(new JSONEndObject);
    return T_END_OBJECT;
}
":" ps->objects.push_back(new JSONNSObject); return T_NAME_SEPARATOR;
"," ps->objects.push_back(new JSONVSObject); return T_VALUE_SEPARATOR;
\"([^\\\"]|\\.)*\" {
    *(yytext+yyleng-1) = 0;
    ps->objects.push_back(new JSONStrValue(yylval.string_ = (yytext+1)));
    return T_STRING;
}
false ps->objects.push_back(new JSONFalse); return T_FALSE;
null  ps->objects.push_back(new JSONNull); return T_NULL;
true  ps->objects.push_back(new JSONTrue); return T_TRUE;
[-+.0123456789eE]+ {
    long double res;
    char* ep;
    errno = 0;
    res = strtold(yytext,&ep);
    if(ep == yytext || *ep != 0 || errno == ERANGE) {
        std::string error("couldn't convert number:  ");
        error.append(yytext);
        yyerror(error.c_str());
    }
    ps->objects.push_back(new JSONNumber(yylval.number_ = res));
    return T_NUMBER;
}
{ws} for(char* cp = yytext; *cp; cp++)if(*cp == '\n')ps->lineno++;
%%
