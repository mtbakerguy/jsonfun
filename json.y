%{
#include <algorithm>
#include <stdlib.h>
#include "JSON.h"

using namespace std;

__thread ParserState* ps;

extern "C" {
extern void yyerror(const char*);
extern int yylex(void);
extern void spit(const char*);
};

#define YYMAXDEPTH 500000

%}

%union {
    const char* string_;
    long double number_;
}

%token T_BEGIN_ARRAY T_END_ARRAY T_END_OBJECT T_BEGIN_OBJECT T_NAME_SEPARATOR T_VALUE_SEPARATOR T_FALSE T_NULL T_TRUE

%token <string_> T_STRING
%token <number_> T_NUMBER

%%

value: object {
    /* load the global pointer with the built JSON* object */
    /* there's probably a more elegant way to do this */
    ps->json = ps->composites.top();
    ps->deferred.push(ps->json);
    ps->composites.pop();
    ps->composites2cleanup.push_back(ps->json);
}
| array       {
    ps->json = ps->composites.top();
    // restore the array ordering
    std::reverse(ps->json->array.begin(),ps->json->array.end());
    ps->deferred.push(ps->json);
    ps->composites.pop();
    ps->composites2cleanup.push_back(ps->json);
}
| T_NUMBER    { ps->deferred.push(ps->objects.back()); }
| T_STRING    { ps->deferred.push(ps->objects.back()); }
| T_FALSE     { ps->deferred.push(ps->objects.back()); }
| T_TRUE      { ps->deferred.push(ps->objects.back()); }
| T_NULL      { ps->deferred.push(ps->objects.back()); }

object: T_BEGIN_OBJECT member T_END_OBJECT {}
| T_BEGIN_OBJECT member T_VALUE_SEPARATOR member T_END_OBJECT {}
| T_BEGIN_OBJECT T_END_OBJECT {}

member: T_STRING T_NAME_SEPARATOR value {
    ps->composites.top()->dictionary[$1] = ps->deferred.top();
    ps->deferred.pop();
}
| T_STRING T_NAME_SEPARATOR value T_VALUE_SEPARATOR member {
    ps->composites.top()->dictionary[$1] = ps->deferred.top();;
    ps->deferred.pop();
}

arrayelt: value {
    ps->composites.top()->array.push_back(ps->deferred.top());
    ps->deferred.pop();
}
| value T_VALUE_SEPARATOR arrayelt {
    ps->composites.top()->array.push_back(ps->deferred.top());
    ps->deferred.pop();
}

array: T_BEGIN_ARRAY arrayelt T_END_ARRAY {}
| T_BEGIN_ARRAY T_END_ARRAY {}

%%

static void  jsonwalk(JSONObject* json) {
    std::map<std::string,JSONObject*>::iterator i;
    std::vector<JSONObject*>::iterator j;
    JSON* k = dynamic_cast<JSON*>(json);

    if(k->dictionary.empty() and k->array.empty()) {
        json->repr();
        return;
    }

    for(i = k->dictionary.begin();i != k->dictionary.end();++i) {
        if((*i).second->type == BASE_) {
            (*i).second->repr();   
            jsonwalk((*i).second);
        }
        else {
            std::cout << (*i).first << ":  ";
            (*i).second->repr();   
        }
    }

    for(j = k->array.begin();j != k->array.end();++j) {
        if((*j)->type == BASE_) {
            std::cout << "Recursing for array" << std::endl;
            (*j)->repr();    
            jsonwalk(*j);
        }
        else {
            (*j)->repr();    
        }
    }
}

int main(void) __attribute ((weak));

int main(void) {
   extern int yyparse(void);
   ParserState state;
   ps = &state;
   yyparse();
   std::vector<JSONObject*>::iterator i;
   unsigned int indent = 0;
    for(i = ps->objects.begin();i != ps->objects.end();++i) {
      if((*i)->type == ENDOBJECT_ || (*i)->type == ENDARRAY_)indent -= 4;
      for(int j=0;j < indent;j++)std::cout << " ";
      (*i)->repr();
      if((*i)->type == BEGINOBJECT_ || (*i)->type == BEGINARRAY_)indent += 4;
   }

   jsonwalk(ps->json); 
   while(! ps->deferred.empty()) {
        std::cout << "deferred: ";
        ps->deferred.top()->repr();
        ps->deferred.pop();
   }
   while(! ps->composites.empty()) {
        std::cout << "composites: ";
        ps->composites.top()->repr();
        ps->composites.pop();
   }
 
   std::cout <<  "lookup test:" << std::endl;
   // test element:  "b" : {"a" : {"c" : 57,"d" : {"hithere" : "hithere2"}}},
   //  should printout number: 57 strvalue: hithere2
   if(ps->json->dictionary.find("b") != ps->json->dictionary.end()) {
     JSON* l1 = (JSON*)ps->json->dictionary["b"];
     JSON* l2 = (JSON*)l1->dictionary["a"];
     JSON* l3 = (JSON*)l2->dictionary["c"];
     JSON* l4 = (JSON*)l2->dictionary["d"];
     JSON* l5 = (JSON*)l4->dictionary["hithere"];
     l3->repr();
     l5->repr();
   }
}
