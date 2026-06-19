%{

#include "symbol_table.h"

#define YYSTYPE symbol_info*

extern FILE *yyin;
int yyparse(void);
int yylex(void);
extern YYSTYPE yylval;

symbol_table *st = NULL;

string current_type;
string currentFunction = "global";
vector<pair<string, string>> current_func_params;
vector<string> current_arg_types;
set<string> func_done;
vector<string> pending_decl_duplicate_errors;

int lines = 1;
int error_count = 0;

ofstream outlog;
ofstream errlog;

static const string ERROR_TYPE = "error";

void report_error(const string &message)
{
	outlog << "At line no: " << lines << " " << message << endl << endl;
	errlog << "At line no: " << lines << " " << message << endl << endl;
	error_count++;
}

void yyerror(char *s)
{
	report_error(string(s));
}

symbol_info *lookup_symbol(const string &name)
{
	if (st == NULL)
		return NULL;
	symbol_info *temp = new symbol_info(name, "ID");
	symbol_info *found = st->lookup(temp);
	delete temp;
	return found;
}

symbol_info *lookup_current_scope_symbol(const string &name)
{
	if (st == NULL)
		return NULL;
	symbol_info *temp = new symbol_info(name, "ID");
	symbol_info *found = st->lookup_current_scope(temp);
	delete temp;
	return found;
}

bool is_error_type(const string &type_name)
{
	return type_name == ERROR_TYPE;
}

bool is_float_type(const string &type_name)
{
	return type_name == "float";
}

bool is_int_type(const string &type_name)
{
	return type_name == "int";
}

bool is_void_type(const string &type_name)
{
	return type_name == "void";
}

bool is_zero_literal(const string &value)
{
	if (value.empty())
		return false;

	char *endptr = NULL;
	double number = strtod(value.c_str(), &endptr);
	return endptr != value.c_str() && *endptr == '\0' && number == 0.0;
}

string merged_numeric_type(const string &left_type, const string &right_type)
{
	if (is_error_type(left_type) || is_error_type(right_type))
		return ERROR_TYPE;
	if (is_void_type(left_type) || is_void_type(right_type))
		return ERROR_TYPE;
	if (is_float_type(left_type) || is_float_type(right_type))
		return "float";
	return "int";
}

void set_symbol_type(symbol_info *sym, const string &type_name)
{
	if (sym != NULL)
	{
		sym->set_data_type(type_name);
	}
}

void flush_pending_declaration_errors()
{
	for (size_t i = 0; i < pending_decl_duplicate_errors.size(); i++)
	{
		report_error("Multiple declaration of variable " + pending_decl_duplicate_errors[i]);
	}
	pending_decl_duplicate_errors.clear();
}

%}

%token IF ELSE FOR WHILE DO BREAK INT CHAR FLOAT DOUBLE VOID RETURN SWITCH CASE DEFAULT CONTINUE PRINTLN ADDOP MULOP INCOP DECOP RELOP ASSIGNOP LOGICOP NOT LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD COMMA SEMICOLON CONST_INT CONST_FLOAT ID

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%

start : program
	{
		outlog<<"At line no: "<<lines<<" start : program "<<endl<<endl;
		outlog<<"Symbol Table"<<endl<<endl;
		if (st != NULL)
		{
			st->print_all_scopes(outlog);
		}
	}
	;

program : program unit
	{
		outlog<<"At line no: "<<lines<<" program : program unit "<<endl<<endl;
		outlog<<$1->getname()+"\n"+$2->getname()<<endl<<endl;
		$$ = new symbol_info($1->getname()+"\n"+$2->getname(),"program");
	}
	| unit
	{
		outlog<<"At line no: "<<lines<<" program : unit "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
		$$ = new symbol_info($1->getname(),"program");
	}
	;

unit : var_declaration
	{
		outlog<<"At line no: "<<lines<<" unit : var_declaration "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
		$$ = new symbol_info($1->getname(),"unit");
	}
	| func_definition
	{
		outlog<<"At line no: "<<lines<<" unit : func_definition "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
		$$ = new symbol_info($1->getname(),"unit");
	}
	| error
	{
		$$ = new symbol_info("","unit");
	}
	;

func_name : ID
	{
		currentFunction = $1->getname();
		$$ = $1;
	}
	;

func_definition : type_specifier func_name LPAREN parameter_list RPAREN
	{
		symbol_info *existing = lookup_symbol(currentFunction);
		if (existing == NULL)
		{
			symbol_info *func = new symbol_info($2->getname(), "ID");
			func->set_as_function($1->getname(), current_func_params);
			st->insert(func);
			func_done.insert(currentFunction);
		}
		else
		{
			if (func_done.find(currentFunction) != func_done.end() || !existing->get_is_function())
			{
				report_error("Multiple declaration of function " + currentFunction);
			}
			else
			{
				if ($1->getname() != existing->get_return_type())
				{
					report_error("Return type mismatch with function declaration in function " + existing->getname());
				}
				func_done.insert(currentFunction);
			}
		}

	}
	compound_statement
	{
		outlog<<"At line no: "<<lines<<" func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement "<<endl<<endl;
		outlog<<$1->getname()<<" "<<$2->getname()<<"("<<$4->getname()<<")\n"<<$7->getname()<<endl<<endl;
		$$ = new symbol_info($1->getname()+" "+$2->getname()+"("+$4->getname()+")\n"+$7->getname(),"func_def");
		current_func_params.clear();
	}
	| type_specifier func_name LPAREN RPAREN
	{
		current_func_params.clear();
		symbol_info *existing = lookup_symbol(currentFunction);
		if (existing == NULL)
		{
			symbol_info *func = new symbol_info($2->getname(), "ID");
			func->set_as_function($1->getname(), current_func_params);
			st->insert(func);
			func_done.insert(currentFunction);
		}
		else
		{
			if (func_done.find(currentFunction) != func_done.end() || !existing->get_is_function())
			{
				report_error("Multiple declaration of function " + currentFunction);
			}
			else
			{
				func_done.insert(currentFunction);
			}
		}
	}
	compound_statement
	{
		outlog<<"At line no: "<<lines<<" func_definition : type_specifier ID LPAREN RPAREN compound_statement "<<endl<<endl;
		outlog<<$1->getname()<<" "<<$2->getname()<<"()\n"<<$6->getname()<<endl<<endl;
		$$ = new symbol_info($1->getname()+" "+$2->getname()+"()\n"+$6->getname(),"func_def");
		current_func_params.clear();
	}
	;

parameter_list : parameter_list COMMA type_specifier ID
	{
		outlog<<"At line no: "<<lines<<" parameter_list : parameter_list COMMA type_specifier ID "<<endl<<endl;
		outlog<<$1->getname()<<","<<$3->getname()<<" "<<$4->getname()<<endl<<endl;
		for (size_t i = 0; i < current_func_params.size(); i++)
		{
			if (current_func_params[i].second == $4->getname())
			{
				report_error("Multiple declaration of variable " + $4->getname() + " in parameter of " + currentFunction);
				break;
			}
		}
		current_func_params.push_back(make_pair($3->getname(), $4->getname()));
		$$ = new symbol_info($1->getname()+","+$3->getname()+" "+$4->getname(),"param_list");
	}
	| parameter_list COMMA type_specifier
	{
		outlog<<"At line no: "<<lines<<" parameter_list : parameter_list COMMA type_specifier "<<endl<<endl;
		outlog<<$1->getname()<<","<<$3->getname()<<endl<<endl;
		current_func_params.push_back(make_pair($3->getname(), ""));
		$$ = new symbol_info($1->getname()+","+$3->getname(),"param_list");
	}
	| type_specifier ID
	{
		outlog<<"At line no: "<<lines<<" parameter_list : type_specifier ID "<<endl<<endl;
		outlog<<$1->getname()<<" "<<$2->getname()<<endl<<endl;
		current_func_params.clear();
		current_func_params.push_back(make_pair($1->getname(), $2->getname()));
		$$ = new symbol_info($1->getname()+" "+$2->getname(),"param_list");
	}
	| type_specifier
	{
		outlog<<"At line no: "<<lines<<" parameter_list : type_specifier "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
		current_func_params.clear();
		current_func_params.push_back(make_pair($1->getname(), ""));
		$$ = new symbol_info($1->getname(),"param_list");
	}
	;

compound_statement : LCURL
	{
		if (st != NULL)
		{
			st->enter_scope();
		}

		for (size_t i = 0; i < current_func_params.size(); i++)
		{
			if (current_func_params[i].second.empty())
				continue;
			symbol_info *param_symbol = new symbol_info(current_func_params[i].second, "ID", current_func_params[i].first);
			if (!st->insert(param_symbol))
			{
				delete param_symbol;
			}
		}
	}
	statements RCURL
	{
		outlog<<"At line no: "<<lines<<" compound_statement : LCURL statements RCURL "<<endl<<endl;
		outlog<<"{\n"+$3->getname()+"\n}"<<endl<<endl;
		$$ = new symbol_info("{\n"+$3->getname()+"\n}","comp_stmnt");
		if (st != NULL)
		{
			st->exit_scope();
		}
	}
	| LCURL
	{
		if (st != NULL)
		{
			st->enter_scope();
		}
	}
	RCURL
	{
		outlog<<"At line no: "<<lines<<" compound_statement : LCURL RCURL "<<endl<<endl;
		outlog<<"{\n}"<<endl<<endl;
		$$ = new symbol_info("{\n}","comp_stmnt");
		if (st != NULL)
		{
			st->exit_scope();
		}
	}
	;

var_declaration : type_specifier declaration_list SEMICOLON
	{
		outlog<<"At line no: "<<lines<<" var_declaration : type_specifier declaration_list SEMICOLON "<<endl<<endl;
		outlog<<$1->getname()<<" "<<$2->getname()<<";"<<endl<<endl;
		$$ = new symbol_info($1->getname()+" "+$2->getname()+";","var_dec");
		flush_pending_declaration_errors();
		if (current_type == "void")
		{
			report_error("variable type can not be void ");
		}
	}
	;

type_specifier : INT
	{
		outlog<<"At line no: "<<lines<<" type_specifier : INT "<<endl<<endl;
		outlog<<"int"<<endl<<endl;
		current_type = "int";
		$$ = new symbol_info("int","type");
	}
	| FLOAT
	{
		outlog<<"At line no: "<<lines<<" type_specifier : FLOAT "<<endl<<endl;
		outlog<<"float"<<endl<<endl;
		current_type = "float";
		$$ = new symbol_info("float","type");
	}
	| VOID
	{
		outlog<<"At line no: "<<lines<<" type_specifier : VOID "<<endl<<endl;
		outlog<<"void"<<endl<<endl;
		current_type = "void";
		$$ = new symbol_info("void","type");
	}
	;

declaration_list : declaration_list COMMA ID
	{
		outlog<<"At line no: "<<lines<<" declaration_list : declaration_list COMMA ID "<<endl<<endl;
		outlog<<$1->getname()+","<<$3->getname()<<endl<<endl;
		$$ = new symbol_info($1->getname()+","+$3->getname(), "decl_list");
		if (lookup_current_scope_symbol($3->getname()) != NULL)
		{
			pending_decl_duplicate_errors.push_back($3->getname());
		}
		else
		{
			string declared_type = (current_type == "void") ? ERROR_TYPE : current_type;
			symbol_info *new_var = new symbol_info($3->getname(), "ID", declared_type);
			new_var->set_category("Variable");
			st->insert(new_var);
		}
	}
	| declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
	{
		outlog<<"At line no: "<<lines<<" declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD "<<endl<<endl;
		outlog<<$1->getname()+","<<$3->getname()<<"["<<$5->getname()<<"]"<<endl<<endl;
		$$ = new symbol_info($1->getname()+","+$3->getname()+"["+$5->getname()+"]", "decl_list");
		if (lookup_current_scope_symbol($3->getname()) != NULL)
		{
			pending_decl_duplicate_errors.push_back($3->getname());
		}
		else
		{
			int size = stoi($5->getname());
			string declared_type = (current_type == "void") ? ERROR_TYPE : current_type;
			symbol_info *new_array = new symbol_info($3->getname(), "ID", declared_type, size);
			st->insert(new_array);
		}
	}
	| ID
	{
		outlog<<"At line no: "<<lines<<" declaration_list : ID "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
		pending_decl_duplicate_errors.clear();
		$$ = new symbol_info($1->getname(), "decl_list");
		if (lookup_current_scope_symbol($1->getname()) != NULL)
		{
			pending_decl_duplicate_errors.push_back($1->getname());
		}
		else
		{
			string declared_type = (current_type == "void") ? ERROR_TYPE : current_type;
			symbol_info *new_var = new symbol_info($1->getname(), "ID", declared_type);
			new_var->set_category("Variable");
			st->insert(new_var);
		}
	}
	| ID LTHIRD CONST_INT RTHIRD
	{
		outlog<<"At line no: "<<lines<<" declaration_list : ID LTHIRD CONST_INT RTHIRD "<<endl<<endl;
		outlog<<$1->getname()<<"["<<$3->getname()<<"]"<<endl<<endl;
		pending_decl_duplicate_errors.clear();
		$$ = new symbol_info($1->getname()+"["+$3->getname()+"]", "decl_list");
		if (lookup_current_scope_symbol($1->getname()) != NULL)
		{
			pending_decl_duplicate_errors.push_back($1->getname());
		}
		else
		{
			int size = stoi($3->getname());
			string declared_type = (current_type == "void") ? ERROR_TYPE : current_type;
			symbol_info *new_array = new symbol_info($1->getname(), "ID", declared_type, size);
			st->insert(new_array);
		}
	}
	;

statements : statement
	{
		outlog<<"At line no: "<<lines<<" statements : statement "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
		$$ = new symbol_info($1->getname(),"stmnts");
	}
	| statements statement
	{
		outlog<<"At line no: "<<lines<<" statements : statements statement "<<endl<<endl;
		outlog<<$1->getname()<<"\n"<<$2->getname()<<endl<<endl;
		$$ = new symbol_info($1->getname()+"\n"+$2->getname(),"stmnts");
	}
	;

statement : var_declaration
	{
		outlog<<"At line no: "<<lines<<" statement : var_declaration "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
		$$ = new symbol_info($1->getname(),"stmnt");
	}
	| func_definition
	{
		outlog<<"At line no: "<<lines<<" statement : func_definition "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
		$$ = new symbol_info($1->getname(),"stmnt");
	}
	| expression_statement
	{
		outlog<<"At line no: "<<lines<<" statement : expression_statement "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
		$$ = new symbol_info($1->getname(),"stmnt");
	}
	| compound_statement
	{
		outlog<<"At line no: "<<lines<<" statement : compound_statement "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
		$$ = new symbol_info($1->getname(),"stmnt");
	}
	| FOR LPAREN expression_statement expression_statement expression RPAREN statement
	{
		outlog<<"At line no: "<<lines<<" statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement "<<endl<<endl;
		outlog<<"for("<<$3->getname()<<$4->getname()<<$5->getname()<<")\n"<<$7->getname()<<endl<<endl;
		$$ = new symbol_info("for("+$3->getname()+$4->getname()+$5->getname()+")\n"+$7->getname(),"stmnt");
	}
	| IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE
	{
		outlog<<"At line no: "<<lines<<" statement : IF LPAREN expression RPAREN statement "<<endl<<endl;
		outlog<<"if("<<$3->getname()<<")\n"<<$5->getname()<<endl<<endl;
		$$ = new symbol_info("if("+$3->getname()+")\n"+$5->getname(),"stmnt");
	}
	| IF LPAREN expression RPAREN statement ELSE statement
	{
		outlog<<"At line no: "<<lines<<" statement : IF LPAREN expression RPAREN statement ELSE statement "<<endl<<endl;
		outlog<<"if("<<$3->getname()<<")\n"<<$5->getname()<<"\nelse\n"<<$7->getname()<<endl<<endl;
		$$ = new symbol_info("if("+$3->getname()+")\n"+$5->getname()+"\nelse\n"+$7->getname(),"stmnt");
	}
	| WHILE LPAREN expression RPAREN statement
	{
		outlog<<"At line no: "<<lines<<" statement : WHILE LPAREN expression RPAREN statement "<<endl<<endl;
		outlog<<"while("<<$3->getname()<<")\n"<<$5->getname()<<endl<<endl;
		$$ = new symbol_info("while("+$3->getname()+")\n"+$5->getname(),"stmnt");
	}
	| PRINTLN LPAREN ID RPAREN SEMICOLON
	{
		outlog<<"At line no: "<<lines<<" statement : PRINTLN LPAREN ID RPAREN SEMICOLON "<<endl<<endl;
		outlog<<"printf("<<$3->getname()<<");"<<endl<<endl;
		$$ = new symbol_info("printf("+$3->getname()+");","stmnt");
		if (lookup_symbol($3->getname()) == NULL)
		{
			report_error("Undeclared variable " + $3->getname());
		}
	}
	| RETURN expression SEMICOLON
	{
		outlog<<"At line no: "<<lines<<" statement : RETURN expression SEMICOLON "<<endl<<endl;
		outlog<<"return "<<$2->getname()<<";"<<endl<<endl;
		$$ = new symbol_info("return "+$2->getname()+";","stmnt");
	}
	;

expression_statement : SEMICOLON
	{
		outlog<<"At line no: "<<lines<<" expression_statement : SEMICOLON "<<endl<<endl;
		outlog<<";"<<endl<<endl;
		$$ = new symbol_info(";","expr_stmt");
	}
	| expression SEMICOLON
	{
		outlog<<"At line no: "<<lines<<" expression_statement : expression SEMICOLON "<<endl<<endl;
		outlog<<$1->getname()<<";"<<endl<<endl;
		$$ = new symbol_info($1->getname()+";","expr_stmt");
	}
	;

variable : ID
	{
		outlog<<"At line no: "<<lines<<" variable : ID "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
		$$ = new symbol_info($1->getname(),"varbl");

		symbol_info *entry = lookup_symbol($1->getname());
		if (entry == NULL)
		{
			report_error("Undeclared variable " + $1->getname());
			set_symbol_type($$, ERROR_TYPE);
		}
		else if (entry->get_is_array())
		{
			report_error("variable is of array type : " + $1->getname());
			set_symbol_type($$, ERROR_TYPE);
		}
		else if (entry->get_is_function())
		{
			set_symbol_type($$, entry->get_return_type());
		}
		else
		{
			set_symbol_type($$, entry->get_data_type());
		}
	}
	| ID LTHIRD expression RTHIRD
	{
		outlog<<"At line no: "<<lines<<" variable : ID LTHIRD expression RTHIRD "<<endl<<endl;
		outlog<<$1->getname()<<"["<<$3->getname()<<"]"<<endl<<endl;
		$$ = new symbol_info($1->getname()+"["+$3->getname()+"]","array");

		symbol_info *entry = lookup_symbol($1->getname());
		if (entry == NULL)
		{
			report_error("Undeclared variable " + $1->getname());
			set_symbol_type($$, ERROR_TYPE);
		}
		else
		{
			if (!entry->get_is_array())
			{
				report_error("variable is not of array type : " + $1->getname());
				set_symbol_type($$, ERROR_TYPE);
			}
			else
			{
				set_symbol_type($$, entry->get_data_type());
			}

			if (!is_error_type($3->get_data_type()) && !is_int_type($3->get_data_type()))
			{
				report_error("array index is not of integer type : " + $1->getname());
			}
		}
	}
	;

expression : logic_expression
	{
		outlog<<"At line no: "<<lines<<" expression : logic_expression "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
		$$ = new symbol_info($1->getname(),"expr");
		set_symbol_type($$, $1->get_data_type());
	}
	| variable ASSIGNOP logic_expression
	{
		outlog<<"At line no: "<<lines<<" expression : variable ASSIGNOP logic_expression "<<endl<<endl;
		outlog<<$1->getname()<<"="<<$3->getname()<<endl<<endl;

		$$ = new symbol_info($1->getname()+"="+$3->getname(),"expr");
		set_symbol_type($$, $1->get_data_type());

		if (!is_error_type($1->get_data_type()) && !is_error_type($3->get_data_type()))
		{
			if (is_void_type($1->get_data_type()) || is_void_type($3->get_data_type()))
			{
				report_error("operation on void type ");
				set_symbol_type($$, ERROR_TYPE);
			}
			else if (is_int_type($1->get_data_type()) && is_float_type($3->get_data_type()))
			{
				report_error("Warning: Assignment of float value into variable of integer type ");
			}
		}
	}
	;

logic_expression : rel_expression
	{
		outlog<<"At line no: "<<lines<<" logic_expression : rel_expression "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
		$$ = new symbol_info($1->getname(),"lgc_expr");
		set_symbol_type($$, $1->get_data_type());
	}
	| rel_expression LOGICOP rel_expression
	{
		outlog<<"At line no: "<<lines<<" logic_expression : rel_expression LOGICOP rel_expression "<<endl<<endl;
		outlog<<$1->getname()<<$2->getname()<<$3->getname()<<endl<<endl;
		$$ = new symbol_info($1->getname()+$2->getname()+$3->getname(),"lgc_expr");
		set_symbol_type($$, "int");

		if (!is_error_type($1->get_data_type()) && !is_error_type($3->get_data_type()))
		{
			if (is_void_type($1->get_data_type()) || is_void_type($3->get_data_type()))
			{
				report_error("operation on void type ");
				set_symbol_type($$, ERROR_TYPE);
			}
		}
	}
	;

rel_expression : simple_expression
	{
		outlog<<"At line no: "<<lines<<" rel_expression : simple_expression "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
		$$ = new symbol_info($1->getname(),"rel_expr");
		set_symbol_type($$, $1->get_data_type());
	}
	| simple_expression RELOP simple_expression
	{
		outlog<<"At line no: "<<lines<<" rel_expression : simple_expression RELOP simple_expression "<<endl<<endl;
		outlog<<$1->getname()<<$2->getname()<<$3->getname()<<endl<<endl;
		$$ = new symbol_info($1->getname()+$2->getname()+$3->getname(),"rel_expr");
		set_symbol_type($$, "int");

		if (!is_error_type($1->get_data_type()) && !is_error_type($3->get_data_type()))
		{
			if (is_void_type($1->get_data_type()) || is_void_type($3->get_data_type()))
			{
				report_error("operation on void type ");
				set_symbol_type($$, ERROR_TYPE);
			}
		}
	}
	;

simple_expression : term
	{
		outlog<<"At line no: "<<lines<<" simple_expression : term "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
		$$ = new symbol_info($1->getname(),"simp_expr");
		set_symbol_type($$, $1->get_data_type());
	}
	| simple_expression ADDOP term
	{
		outlog<<"At line no: "<<lines<<" simple_expression : simple_expression ADDOP term "<<endl<<endl;
		outlog<<$1->getname()<<$2->getname()<<$3->getname()<<endl<<endl;
		$$ = new symbol_info($1->getname()+$2->getname()+$3->getname(),"simp_expr");
		set_symbol_type($$, merged_numeric_type($1->get_data_type(), $3->get_data_type()));

		if (!is_error_type($1->get_data_type()) && !is_error_type($3->get_data_type()))
		{
			if (is_void_type($1->get_data_type()) || is_void_type($3->get_data_type()))
			{
				report_error("operation on void type ");
				set_symbol_type($$, ERROR_TYPE);
			}
		}
	}
	;

term : unary_expression
	{
		outlog<<"At line no: "<<lines<<" term : unary_expression "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
		$$ = new symbol_info($1->getname(),"term");
		set_symbol_type($$, $1->get_data_type());
	}
	| term MULOP unary_expression
	{
		outlog<<"At line no: "<<lines<<" term : term MULOP unary_expression "<<endl<<endl;
		outlog<<$1->getname()<<$2->getname()<<$3->getname()<<endl<<endl;
		$$ = new symbol_info($1->getname()+$2->getname()+$3->getname(),"term");
		set_symbol_type($$, merged_numeric_type($1->get_data_type(), $3->get_data_type()));

		if (!is_error_type($1->get_data_type()) && !is_error_type($3->get_data_type()))
		{
			if (is_void_type($1->get_data_type()) || is_void_type($3->get_data_type()))
			{
				report_error("operation on void type ");
				set_symbol_type($$, ERROR_TYPE);
			}
			else if ($2->getname() == "%")
			{
				if (is_zero_literal($3->getname()))
				{
					report_error("Modulus by 0 ");
				}
				if (!is_int_type($1->get_data_type()) || !is_int_type($3->get_data_type()))
				{
					report_error("Modulus operator on non integer type ");
					set_symbol_type($$, ERROR_TYPE);
				}
				else
				{
					set_symbol_type($$, "int");
				}
			}
			else
			{
				if ($2->getname() == "/" && is_zero_literal($3->getname()))
				{
					report_error("Division by 0");
				}
				set_symbol_type($$, merged_numeric_type($1->get_data_type(), $3->get_data_type()));
			}
		}
	}
	;

unary_expression : ADDOP unary_expression
	{
		outlog<<"At line no: "<<lines<<" unary_expression : ADDOP unary_expression "<<endl<<endl;
		outlog<<$1->getname()<<$2->getname()<<endl<<endl;
		$$ = new symbol_info($1->getname()+$2->getname(),"un_expr");
		set_symbol_type($$, $2->get_data_type());
	}
	| NOT unary_expression
	{
		outlog<<"At line no: "<<lines<<" unary_expression : NOT unary_expression "<<endl<<endl;
		outlog<<"!"<<$2->getname()<<endl<<endl;
		$$ = new symbol_info("!"+$2->getname(),"un_expr");
		set_symbol_type($$, $2->get_data_type());
	}
	| factor
	{
		outlog<<"At line no: "<<lines<<" unary_expression : factor "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
		$$ = new symbol_info($1->getname(),"un_expr");
		set_symbol_type($$, $1->get_data_type());
	}
	;

factor : variable
	{
		outlog<<"At line no: "<<lines<<" factor : variable "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
		$$ = new symbol_info($1->getname(),"fctr");
		set_symbol_type($$, $1->get_data_type());
	}
	| ID LPAREN argument_list RPAREN
	{
		outlog<<"At line no: "<<lines<<" factor : ID LPAREN argument_list RPAREN "<<endl<<endl;
		outlog<<$1->getname()<<"("<<$3->getname()<<")"<<endl<<endl;
		$$ = new symbol_info($1->getname()+"("+$3->getname()+")","fctr");

		symbol_info *entry = lookup_symbol($1->getname());
		if (entry == NULL)
		{
			report_error("Undeclared function: " + $1->getname());
			set_symbol_type($$, ERROR_TYPE);
		}
		else if (!entry->get_is_function())
		{
			report_error("Not a function: " + $1->getname());
			set_symbol_type($$, ERROR_TYPE);
		}
		else
		{
			vector<pair<string, string>> params = entry->get_parameters();
			bool has_error_arg = false;
			for (size_t i = 0; i < current_arg_types.size(); i++)
			{
				if (is_error_type(current_arg_types[i]))
				{
					has_error_arg = true;
					break;
				}
			}

			if (!has_error_arg && current_arg_types.size() != params.size())
			{
				report_error("Inconsistencies in number of arguments in function call: " + $1->getname());
			}
			else if (!has_error_arg)
			{
				for (size_t i = 0; i < current_arg_types.size(); i++)
				{
					string param_type = params[i].first;
					string arg_type = current_arg_types[i];
					if ((param_type == "int" && arg_type == "float") || (param_type == "float" && arg_type == "int"))
					{
						report_error("argument " + to_string(i + 1) + " type mismatch in function call: " + $1->getname());
					}
				}
			}

			set_symbol_type($$, entry->get_return_type());
			if (entry->get_return_type() == "void")
			{
				set_symbol_type($$, "void");
			}
		}

		current_arg_types.clear();
	}
	| LPAREN expression RPAREN
	{
		outlog<<"At line no: "<<lines<<" factor : LPAREN expression RPAREN "<<endl<<endl;
		outlog<<"("<<$2->getname()<<")"<<endl<<endl;
		$$ = new symbol_info("("+$2->getname()+")","fctr");
		set_symbol_type($$, $2->get_data_type());
	}
	| CONST_INT
	{
		outlog<<"At line no: "<<lines<<" factor : CONST_INT "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
		$$ = new symbol_info($1->getname(),"fctr");
		set_symbol_type($$, "int");
	}
	| CONST_FLOAT
	{
		outlog<<"At line no: "<<lines<<" factor : CONST_FLOAT "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
		$$ = new symbol_info($1->getname(),"fctr");
		set_symbol_type($$, "float");
	}
	| variable INCOP
	{
		outlog<<"At line no: "<<lines<<" factor : variable INCOP "<<endl<<endl;
		outlog<<$1->getname()<<"++"<<endl<<endl;
		$$ = new symbol_info($1->getname()+"++","fctr");
		set_symbol_type($$, $1->get_data_type());
	}
	| variable DECOP
	{
		outlog<<"At line no: "<<lines<<" factor : variable DECOP "<<endl<<endl;
		outlog<<$1->getname()<<"--"<<endl<<endl;
		$$ = new symbol_info($1->getname()+"--","fctr");
		set_symbol_type($$, $1->get_data_type());
	}
	;

argument_list : arguments
	{
		outlog<<"At line no: "<<lines<<" argument_list : arguments "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
		$$ = new symbol_info($1->getname(),"arg_list");
	}
	|
	{
		outlog<<"At line no: "<<lines<<" argument_list :  "<<endl<<endl;
		outlog<<""<<endl<<endl;
		current_arg_types.clear();
		$$ = new symbol_info("","arg_list");
	}
	;

arguments : arguments COMMA logic_expression
	{
		outlog<<"At line no: "<<lines<<" arguments : arguments COMMA logic_expression "<<endl<<endl;
		outlog<<$1->getname()<<","<<$3->getname()<<endl<<endl;
		current_arg_types.push_back($3->get_data_type());
		$$ = new symbol_info($1->getname()+","+$3->getname(),"arg");
	}
	| logic_expression
	{
		outlog<<"At line no: "<<lines<<" arguments : logic_expression "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
		current_arg_types.clear();
		current_arg_types.push_back($1->get_data_type());
		$$ = new symbol_info($1->getname(),"arg");
	}
	;

%%

int main(int argc, char *argv[])
{
	if(argc != 2)
	{
		cout<<"Please input file name"<<endl;
		return 0;
	}

	yyin = fopen(argv[1], "r");
	outlog.open("22101235_22101870_log.txt", ios::trunc);
	errlog.open("22101235_22101870_error.txt", ios::trunc);

	if(yyin == NULL)
	{
		cout<<"Couldn't open file"<<endl;
		outlog.close();
		errlog.close();
		return 0;
	}

	st = new symbol_table(10);
	st->enter_scope();

	yyparse();

	outlog<<endl<<"Total lines: "<<lines<<endl;
	outlog<<"Total errors: "<<error_count<<endl;
	errlog<<"Total errors: "<<error_count<<endl;

	delete st;
	outlog.close();
	errlog.close();
	fclose(yyin);

	return 0;
}
