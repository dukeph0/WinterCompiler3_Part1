/* cs152-miniL phase3 */
%{
#include<iostream>
#include<stdio.h>
#include<string>
#include<vector>
#include<string.h>
#include<sstream>
#include<fstream>


extern int yylex(void);
void yyerror(const char *msg);
extern int col;

char *identToken;
int numberToken;
int  count_names = 0;

//every symbol has a name, value, type(either Integer or Array), 

enum Type { Integer, Array };
struct Symbol {
  std::string name;
  Type type;
};
struct Function {
  std::string name;
  std::vector<Symbol> declarations;
};
/*struct CodeNode{
  std::string code;
  std::string name;
};*/

std::vector <Function> symbol_table;
std::stringstream out;

std::string gen_temp() {
  static int count = 0;
  return "__temp__" + std::to_string(count++);
}
std::string gen_loop(){
  static int count = 0;
  return "loop" + std::to_string(count++);
}
Function *get_function() {
  int last = symbol_table.size()-1;
  return &symbol_table[last];
}

bool find(std::string &value) {
  Function *f = get_function();
  for(int i=0; i < f->declarations.size(); i++) {
    Symbol *s = &f->declarations[i];
    if (s->name == value) {
      return true;
    }
  }
  return false;
}

void add_function_to_symbol_table(std::string &value) {
  Function f; 
  f.name = value; 
  symbol_table.push_back(f);
}

void add_variable_to_symbol_table(std::string &value, Type t) {
  Symbol s;
  s.name = value;
  s.type = t;
  Function *f = get_function();
  f->declarations.push_back(s);
}
Type get_type(std::string &value)
{
  for(int i=0; i<symbol_table.size(); i++) {
    for(int j=0; j<symbol_table[i].declarations.size(); j++) {
      if (symbol_table[i].declarations[j].name.c_str() == value)
      {
        return symbol_table[i].declarations[j].type;
      }
    }
  }
}

void print_symbol_table(void) {
  printf("symbol table:\n");
  printf("--------------------\n");
  for(int i=0; i<symbol_table.size(); i++) {
    printf("function: %s\n", symbol_table[i].name.c_str());
    for(int j=0; j<symbol_table[i].declarations.size(); j++) {
      printf("  locals: %s\n", symbol_table[i].declarations[j].name.c_str());
    }
  }
  printf("--------------------\n");
}


%}


%union {
  char *op_val;
  //struct CodeNode *node;
}

//%error-verbose
%locations
%define parse.error verbose

/* %start program */
%start prog_start

%token FUNCTION
%token BEGIN_PARAMS
%token END_PARAMS
%token BEGIN_LOCALS
%token END_LOCALS
%token BEGIN_BODY
%token END_BODY
%token INTEGER
%token ARRAY
%token OF 
%token IF
%token THEN
%token ENDIF
%token ELSE
%token WHILE
%token DO
%token BEGINLOOP
%token ENDLOOP
%token CONTINUE
%token BREAK
%token READ
%token WRITE
%right NOT
%token TRUE
%token FALSE
%token RETURN
%token <op_val> NUMBER
%token <op_val> IDENT
%token SEMICOLON 
%token COLON 
%token COMMA
%token L_PAREN 
%token R_PAREN
%token L_SQUARE_BRACKET 
%token R_SQUARE_BRACKET

%left SUB ADD
%left MULT DIV
%left MOD NEQ
%left EQ ASSIGN
%left LT GT
%token LTE GTE

%type<op_val> identifier identifiers term comp
%type<op_val> statement expression multiplicative_expr
%type<op_val> variable declaration declarations bool_expr2


%%
  /* write your rules here */
/*Start*/
prog_start:  functions {}
;

/*Function and Functions*/
function: FUNCTION IDENT
{
  //midrule: 
  //add the function to the symbol table and print 
    std::string func_name = $2;
    add_function_to_symbol_table(func_name);
    out << "func " << func_name << std::endl;
  
} SEMICOLON BEGIN_PARAMS declarations END_PARAMS BEGIN_LOCALS declarations END_LOCALS BEGIN_BODY statements END_BODY
{

  out << "endfunc" << std::endl;

}
;
functions: function functions {} 
  | {}
;

/*Identifier and Identifiers*/
identifier: IDENT 
{
    /*CodeNode *node = new CodeNode;
    node->code = " ";
    node->name = $1;
    if(find(unsigned node->name))
    {
      yyerror(node->name);
      YYABORT;
    }
    $$ = node; //passes it up the grammar */
    
    $$=$1;
} 
;
identifiers: identifier COMMA identifiers {} 
| identifier 
  {
    $$ = $1;
  } 
;



/*Declartion and Declarations*/
declaration: identifiers COLON INTEGER
{
    /*CodeNode *node = new CodeNode;
    node->code = " ";
    node->name = $1;*/
    std::string value = $1;
    Type t = Integer;
  add_variable_to_symbol_table(value, t);
  out << ". " << value << std::endl;
} 
            | identifiers COLON ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET OF INTEGER 
{
  std::string value = $1;
  Type t = Array;
  add_variable_to_symbol_table(value, t);
  out << ".[] " << value << ", " <<  $5 << std::endl;
}
;
declarations: declaration SEMICOLON declarations {} 
  | {}
;

/*Statement and Statements*/
statement:    variable ASSIGN expression 
{
  // = dst, src AND = dst,$0
  std::string var = $1;
  Type t;
  if(find(var))
  {
    if(get_type(var) == Array)
    {
      out << "[]= " << $1 << ", " << $3 << std::endl;
    }
    else
    {
      out << "= " << $1 << ", " << $3 << std::endl;
    }
  }
  
  /*CodeNode *node = new CodeNode;
  node->code = $3->code;
  node->code += std::string("= ") + dst + std::string(", ") + std::string("\n");
  out << "= " << dst << ", " << std::endl;
  $$ = node;*/

}
  | IF bool_expr THEN statements ENDIF {}
  | IF bool_expr THEN statements ELSE statements ENDIF {}
  | WHILE bool_expr BEGINLOOP
  {
    std::string loop = gen_loop();
    out << ": begin" << loop << std::endl;
  } statements ENDLOOP {}
  | DO BEGINLOOP
  {
    std::string loop = gen_loop();
    out << ": begin" << loop << std::endl;
  } statements ENDLOOP WHILE bool_expr {}
  | READ variable {}
  | WRITE variable 
  {
    // .> .>[]
    out << ".> " <<  $2 << std::endl;
  }
  | CONTINUE {}
  | BREAK {}
  | RETURN expression {}
;
statements:   statement SEMICOLON statements {}
              | {}
;
/*BoolExpr*/
bool_expr: bool_expr2 {}
          | NOT bool_expr2 {}
;
bool_expr2:  expression comp expression
            {
                std::string temp = gen_temp();
                out << ". " << temp << std::endl;
                out << $2 << " " << temp << ", " << $1 << ", " << $3 << std::endl;
                char* c = strcpy(new char[temp.length() + 1], temp.c_str());
                $$ = c;
            }
            | L_PAREN bool_expr R_PAREN {}
;
/* Comparison */
comp:   EQ {}
        | NEQ {}
        | LT {}
        | GT 
        {
          $$ = strcpy(new char[1], ">");
        }
        | LTE 
        {
          $$ = strcpy(new char[2], "<=");
        }
        | GTE {}
;
/* Expression and Expressions*/
expression:   multiplicative_expr {}
              | multiplicative_expr SUB expression
              {
                std::string temp = gen_temp();
                out << ". " << temp << std::endl;
                out << "- " << temp << ", " << $1 << ", " << $3 << std::endl;
                char* c = strcpy(new char[temp.length() + 1], temp.c_str());
                $$ = c;
              }
              | multiplicative_expr ADD expression 
              {
                std::string temp = gen_temp();
                out << ". " << temp << std::endl;
                out << "+ " << temp << ", " << $1 << ", " << $3 << std::endl;
                char* c = strcpy(new char[temp.length() + 1], temp.c_str());
                $$ = c;
              }
;
expressions:   expression {}
              | expression COMMA expressions {}
              | {}
;
/*Multiplicative Expression*/
multiplicative_expr:   term 
                      {
                        $$ = $1;  
                      }
                      | term DIV multiplicative_expr 
                      {
                        std::string temp = gen_temp();
                        out << ". " << temp << std::endl;
                        out << "/ " << temp << ", " << $1 << ", " << $3 << std::endl;
                        char* c = strcpy(new char[temp.length() + 1], temp.c_str());
                        $$ = c;
                      }
                      | term MULT multiplicative_expr
                      {
                        std::string temp = gen_temp();
                        out << ". " << temp << std::endl;
                        out << "* " << temp << ", " << $1 << ", " << $3 << std::endl;
                        char* c = strcpy(new char[temp.length() + 1], temp.c_str());
                        $$ = c;
                      }
                      | term MOD multiplicative_expr 
                      {
                        std::string temp = gen_temp();
                        out << ". " << temp << std::endl;
                        out << "% " << temp << ", " << $1 << ", " << $3 << std::endl;
                        char* c = strcpy(new char[temp.length() + 1], temp.c_str());
                        $$ = c;
                      } 
;
/* Term */
term:   variable 
        {
          $$ = $1;
        }
        | NUMBER 
        {
          $$ = $1;
        }
        | L_PAREN expression R_PAREN {}
        | IDENT L_PAREN expressions R_PAREN {}
        | IDENT L_PAREN R_PAREN {} 
;
/*Variable and Variables*/
variable:   IDENT 
            {
              
              /*CodeNode *node = new CodeNode;
              node->code = " ";
              node->name = $1;
              if(find(node->name))
              {
                yyerror(node->name);
                YYABORT;
              }
              $$ = node; //passes it up the grammar */
              $$ = $1;
            }
            | IDENT L_SQUARE_BRACKET expression R_SQUARE_BRACKET 
            {
              //Here we need too figure out how to do the array identifier
              $$ = $1;
            }
;
%%
int main(int argc, char **argv)
{
   yyparse();
   print_symbol_table();
   std::ofstream file("out.mil");
   file << out.str() << std::endl;
   return 0;
}

void yyerror(const char *msg)
{
   printf("** Line %d: %s\n", col, msg);
   exit(1);
}
