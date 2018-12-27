#include <vector>
#include "JSON.h"

int main(void) {
   extern int yydebug;
   extern int yyparse(void);
   extern __thread ParserState* ps;
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
   return 0;
}
