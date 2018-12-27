#include <vector>
#include <map>
#include <stack>
#include <string>
#include <iostream>
#include <stdlib.h>

typedef enum {
    BASE_=0,
    NUMBER_,
    STRING_,
    FALSE_,
    TRUE_,
    NULL_,
    BEGINARRAY_,
    ENDARRAY_,
    BEGINOBJECT_,
    ENDOBJECT_,
    NAMESEP_,
    VALSEP_
} JsonType_t;

struct JSONObject {
    JSONObject() : type(BASE_) {}
    virtual ~JSONObject() {}
    virtual void repr() { std::cout << "object" << std::endl; }
    JsonType_t type;
};

struct JSONNumber : JSONObject {
    JSONNumber(long double number_) : number(number_) {
        type = NUMBER_;
    }
    virtual ~JSONNumber() {}
    virtual void repr() { std::cout << "number:  " << number << std::endl; }
    long double number;
};

struct JSONStrValue : JSONObject {
    JSONStrValue(const char* value_) : value(value_) {
       type = STRING_;
    }
    virtual ~JSONStrValue() {}
    virtual void repr() { std::cout << "strvalue:  " << value << std::endl; }
    std::string value;
};

struct JSONFalse : JSONObject {
    JSONFalse() {
        type = FALSE_;
    }
    virtual void repr() { std::cout << "false" << std::endl; }
    virtual ~JSONFalse() {}
};

struct JSONTrue : JSONObject {
    JSONTrue() {
       type = TRUE_;
    }
    virtual void repr() { std::cout << "true" << std::endl; }
    virtual ~JSONTrue() {}
};

struct JSONNull : JSONObject {
    JSONNull() {
        type = NULL_;
    }
    virtual void repr() { std::cout << "null" << std::endl; }
    virtual ~JSONNull() {}
};

struct JSONBeginArray : JSONObject {
    JSONBeginArray() {
        type = BEGINARRAY_;
    }
    virtual void repr() { std::cout << "[" << std::endl; }
    virtual ~JSONBeginArray() {}
};

struct JSONEndArray : JSONObject {
    JSONEndArray() {
        type = ENDARRAY_;
    }
    virtual void repr() { std::cout << "]" << std::endl; }
    virtual ~JSONEndArray() {}
};

struct JSONBeginObject : JSONObject {
    JSONBeginObject() {
        type = BEGINOBJECT_;
    }
    virtual void repr() {  std::cout << "{" << std::endl;}
    virtual ~JSONBeginObject() {}
};

struct JSONEndObject : JSONObject {
    JSONEndObject() {
        type = ENDOBJECT_;
    }
    virtual void repr() {  std::cout << "}" << std::endl;}
    virtual ~JSONEndObject() {}
};

struct JSONNSObject : JSONObject {
    JSONNSObject() {
        type = NAMESEP_;
    }
    virtual void repr() { std::cout << "namesep" << std::endl; }
    virtual ~JSONNSObject() {}
};

struct JSONVSObject : JSONObject {
    JSONVSObject() {
        type = VALSEP_;
    }
    virtual void repr() { std::cout << "valsep" << std::endl; }
    virtual ~JSONVSObject() {}
};

// convenience object for users
// NB:  this is separate from JSONObject to avoid memory overhead/object
//      in the derived objects.
struct JSON : JSONObject {
    JSON() {}
    virtual ~JSON() {}
  
    std::map<std::string,JSONObject*> dictionary;
    std::vector<JSONObject*> array;
};

struct ParserState {
    ParserState() : lineno(1) {}
    virtual ~ParserState() {
        // cleanup is semi-simple --> the token objects from the lexer and
        //   the composite objects created for JSON arrays and objects.
 
        std::vector<JSONObject*>::iterator i;
        for(i = objects.begin();i != objects.end();++i)delete *i;

        std::vector<JSON*>::iterator j;
        for(j = composites2cleanup.begin(); j != composites2cleanup.end();++j)
            delete *j;
    }

    std::stack<JSONObject*> deferred;
    std::stack<JSON*> composites;
    std::vector<JSONObject*> objects;
    std::vector<JSON*> composites2cleanup;
    unsigned int lineno;
    JSON* json;
};
