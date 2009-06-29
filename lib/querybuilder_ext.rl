#include <ruby.h>

static VALUE rb_QueryBuilder   = Qnil;
static VALUE rb_Parser         = Qnil;
static VALUE rb_QueryException = Qnil;

/* symbols */
static VALUE _query;
static VALUE _string;
static VALUE _integer;
static VALUE _real;
static VALUE _field;
static VALUE _relation;
static VALUE _interval;
static VALUE _scope;
static VALUE _filter;
static VALUE _offset;
static VALUE _param;
static VALUE _paginate;
static VALUE _limit;
static VALUE _group;
static VALUE _order;
static VALUE _from;
static VALUE _clause;
static VALUE _clause_and;
static VALUE _clause_or;
static VALUE _clause_par;
static VALUE _clause_par_close;
static VALUE _par;
static VALUE _par_close;


/* methods */
static ID _insert;
static ID _apply_op;
static ID _downcase;
static ID _pop_stack;

/* methods */
static VALUE rb_parse(VALUE self, VALUE string);

#define STORE_SYM(k) _##k = ID2SYM(rb_intern(#k));

/* init */
void Init_querybuilder_ext() {
  rb_QueryBuilder = rb_define_module("QueryBuilder");
  rb_Parser = rb_define_class_under(rb_QueryBuilder, "Parser", rb_cObject);
	rb_define_singleton_method(rb_Parser, "parse", rb_parse, 1);
	
	/* store symbols */
  STORE_SYM(query);
	STORE_SYM(string);
  STORE_SYM(integer);
  STORE_SYM(real);
  STORE_SYM(field);
  STORE_SYM(relation);
  STORE_SYM(interval);
  STORE_SYM(scope);
  STORE_SYM(filter);
  STORE_SYM(offset);
  STORE_SYM(param);
  STORE_SYM(paginate);
  STORE_SYM(limit);
  STORE_SYM(group);
  STORE_SYM(order);
  STORE_SYM(from);
  STORE_SYM(clause);
  STORE_SYM(clause_and);
  STORE_SYM(clause_or);
  STORE_SYM(clause_par);
  STORE_SYM(clause_par_close);
  STORE_SYM(par);
  STORE_SYM(par_close);
  
  /* methods */
  _insert    = rb_intern("insert");
  _apply_op  = rb_intern("apply_op");
  _downcase  = rb_intern("downcase");
  _pop_stack = rb_intern("pop_stack");
  
  /* classes */
  rb_QueryException = rb_const_get(rb_QueryBuilder, rb_intern("QueryException"));
}

/* macro */
#define SET_TMP_ARY(sym) tmp = rb_ary_new(); \
  rb_ary_push(tmp, sym); \
  rb_ary_push(tmp, rb_str_new(str_a, p - str_a)); \
  str_a = NULL;

#define SET_TMP_STR tmp = rb_str_new(str_a, p - str_a); \
  str_a = NULL;

#define APPLY_OP(elem) last = rb_funcall(self, _apply_op, 2, stack, elem);

%%{
  machine querybuilder;

  action str_a {
    if (str_a == NULL) str_a = p;
  }

  action string {
    SET_TMP_ARY(_string);
    rb_ary_push(last, tmp);
  }

  action integer {
    SET_TMP_ARY(_integer);
    rb_ary_push(last, tmp);
  }

  action real {
    SET_TMP_ARY(_real);
    rb_ary_push(last, tmp);
  }

  action field {
    SET_TMP_ARY(_field);
    rb_ary_push(last, tmp);
  }

  action direction {
    SET_TMP_STR;
    tmp = ID2SYM(rb_to_id(rb_funcall(tmp, _downcase, 0)));
    // last = apply_op(stack, str_buf.downcase.to_sym, false)
    last = rb_funcall(self, _apply_op, 3, stack, tmp, Qfalse);
  }

  action relation {
    // if clause_state == :relation || clause_state == :parenthesis
    //   last = insert(stack, [:relation, str_buf])
    //   str_buf = ""
    // end
    if (clause_state & (CLAUSE_RELATION | CLAUSE_PARENTHESIS)) {
      SET_TMP_ARY(_relation);
      last = rb_funcall(self, _insert, 2, stack, tmp);
    }
  }

  action operator {
    SET_TMP_STR;
    tmp = ID2SYM(rb_to_id(rb_funcall(tmp, _downcase, 0)));
    APPLY_OP(tmp);
    // last = apply_op(stack, str_buf.downcase.to_sym)
  }

  action interval {
    // last = apply_op(stack, :interval)
    APPLY_OP(_interval);
    SET_TMP_STR;
    // last << str_buf
    rb_ary_push(last, tmp);
  }

  action filter {
    // last = apply_op(stack, :filter)
    APPLY_OP(_filter);
    clause_state = CLAUSE_FILTER;
  }

  action goto_expr_p {
    // # remember current machine state 'cs'
    // last << [:par, cs]
    tmp = rb_ary_new();
    rb_ary_push(tmp, _par);
    rb_ary_push(tmp, INT2NUM(cs));
    rb_ary_push(last, tmp);
    // stack.push last.last
    rb_ary_push(stack, tmp);
    // last = last.last
    last = tmp;
    fgoto expr_p;
  }

  action expr_close {
    // pop_stack(stack, :par_close)
    rb_funcall(self, _pop_stack, 2, stack, _par_close);
    // # reset machine state 'cs'
    // cs = stack.last.delete_at(1)
    tmp = rb_ary_entry(stack, -1);
    tmp = rb_ary_delete_at(tmp, 1);
    cs  = NUM2INT(tmp);
    // # one more time to remove [:par...] line
    // stack.pop
    rb_ary_pop(stack);
    // last = stack.last
    last = rb_ary_entry(stack, -1);
    // # closing ')' must be parsed twice
    fhold;
  }

  action goto_clause_p {
    clause_state = CLAUSE_PARENTHESIS;
    // # remember current machine state 'cs'
    // last << [:clause_par, cs]
    tmp = rb_ary_new();
    rb_ary_push(tmp, _clause_par);
    rb_ary_push(tmp, INT2NUM(cs));
    rb_ary_push(last, tmp);
    // stack.push last.last
    rb_ary_push(stack, tmp);
    // last = last.last
    last = tmp;
    fgoto clause_p;
  }

  action clause_close {
    clause_state = CLAUSE_RELATION;
    // pop_stack(stack, :clause_par_close)
    rb_funcall(self, _pop_stack, 2, stack, _clause_par_close);
    // # reset machine state 'cs'
    // cs = stack.last.delete_at(1)
    tmp = rb_ary_entry(stack, -1);
    tmp = rb_ary_delete_at(tmp, 1);
    cs  = NUM2INT(tmp);
    // # one more time to remove [:par...] line
    // stack.pop
    rb_ary_pop(stack);
    // last = stack.last
    last = rb_ary_entry(stack, -1);
    // # closing ')' must be parsed twice
    fhold;
  }

  action scope {
    // last = apply_op(stack, :scope)
    APPLY_OP(_scope);
    // last << str_buf
    SET_TMP_STR;
    rb_ary_push(last, tmp);
  }

  action offset {
    // last = apply_op(stack, :offset)
    APPLY_OP(_offset);
    // str_buf = ""
    str_a = NULL;
  }

  action param {
    // last << [:param, str_buf]
    SET_TMP_ARY(_param);
    rb_ary_push(last, tmp);
  }

  action paginate {
    // last = apply_op(stack, :paginate)
    APPLY_OP(_paginate);
    // str_buf = ""
    str_a = NULL;
  }

  action limit {
    // last = apply_op(stack, :limit)
    APPLY_OP(_limit);
    // str_buf = ""
    str_a = NULL;
  }

  action order {
    // last = apply_op(stack, :order)
    APPLY_OP(_order);
    // str_buf = ""
    str_a = NULL;
  }

  action group {
    // last = apply_op(stack, :group)
    APPLY_OP(_group);
    // str_buf = ""
    str_a = NULL;
  }

  action from_ {
    // last = apply_op(stack, :from)
    APPLY_OP(_from);
    // str_buf = ""
    str_a = NULL;
    clause_state = CLAUSE_RELATION;
  }

  action join_clause {
    // if clause_state == :relation
    //   last = apply_op(stack, "clause_#{str_buf}".to_sym)
    //   str_buf = ""
    // end
    if (clause_state & CLAUSE_RELATION) {
      if (*str_a == 'a') {
        APPLY_OP(_clause_and);
      } else {
        APPLY_OP(_clause_or);
      }
      str_a = NULL;
    }
  }

  action clause {
    // last = insert(stack, [:clause])
    tmp = rb_ary_new();
    rb_ary_push(tmp, _clause);
    last = rb_funcall(self, _insert, 2, stack, tmp);
    str_a = NULL;
  }

  action error {
    p = p - 3;
    if (p < data) p = data;
    // raise QueryException.new("Syntax error near #{data[p..-1].chomp.inspect}.")
    rb_raise(rb_QueryException, "Syntax error near %s.", RSTRING_PTR(rb_str_inspect(rb_str_new(p , pe - p - 1))));
  }

  action debug {
    // printf("_%c", data[p]);
  }

  include querybuilder "querybuilder_syntax.rl";
}%%

%% write data;

#define CLAUSE_RELATION    1
#define CLAUSE_PARENTHESIS 2
#define CLAUSE_FILTER      4

VALUE rb_parse(VALUE self, VALUE arg) {
  VALUE stack, last, tmp;
  // if string.kind_of?(Array)  // rb_type(string) == T_ARRAY
  if (rb_type(arg) == T_ARRAY) {
    // data = "(#{arg.join(') or (')})\n"
    tmp = rb_str_new2("(");
    rb_str_append(tmp, rb_ary_join(arg, rb_str_new2(") or (")));
    rb_str_append(tmp, rb_str_new2(")\n"));
  } else if (rb_type(arg) == T_STRING) {
    // data = "#{arg}\n"
    tmp = rb_str_plus(arg, rb_str_new2("\n"));
  } else {
    rb_raise(rb_QueryException, "Bad element type: Parser only accepts strings.");
  }
  const char * data = RSTRING_PTR(tmp);
  
  int cs;
  const char * p     = data;
  const char * pe    = data + RSTRING_LEN(tmp);
  const char * eof   = pe;
  const char * str_a = NULL;
   
  // last  = [:query]
  last  = rb_ary_new();
  rb_ary_push(last, _query);
  // stack = [last]
  stack = rb_ary_new();
  rb_ary_push(stack, last);
  
  /* clause_state = :relation */
  int clause_state = CLAUSE_RELATION;
  
  
  %% write init;
  %% write exec;
  
  // raise QueryException.new("Syntax error near #{data[p..-1].chomp.inspect}.") if p != pe
  if (p < pe) {
    p = p - 3;
    if (p < data) p = data;
    rb_raise(rb_QueryException, "Syntax error near %s.", RSTRING_PTR(rb_str_inspect(rb_str_new(p , pe - p - 1))));
  }
  
  return rb_ary_entry(stack, 0);
}