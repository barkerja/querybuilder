module QueryBuilder
  class Parser
  %%{
    machine querybuilder;

    action str_a {
      str_buf += fc.chr
    }

    action string {
      last << [:string, str_buf]
      str_buf = ""
    }

    action dstring {
      last << [:dstring, str_buf]
      str_buf = ""
    }

    action rubyless {
      last << [:rubyless, str_buf]
      str_buf = ""
    }

    action integer {
      last << [:integer, str_buf]
      str_buf = ""
    }

    action real {
      last << [:real, str_buf]
      str_buf = ""
    }

    action field {
      last << [:field, str_buf]
      str_buf = ""
    }

    action method {
      last << [:method, str_buf]
      str_buf = ""
    }

    action raw {
      last << [:raw, str_buf]
      str_buf = ""
    }

    action select_one {
      last = apply_op(stack, :select_one)
      last << str_buf
      str_buf = ""
      # last should be [:select, ...], not the [:select_one] just added.
      stack.pop
      last = stack.last
    }

    action function {
      last = apply_op(stack, :function)
      str_buf = ""
    }

    action direction {
      last = apply_op(stack, str_buf.downcase.to_sym, false)
      str_buf = ""
    }

    action relation {
      if clause_state == :relation || clause_state == :parenthesis
        last = insert(stack, [:relation, str_buf])
        str_buf = ""
      end
    }

    action operator {
      last = apply_op(stack, str_buf.downcase.to_sym)
      str_buf = ""
    }

    action in_op {
      last = apply_op(stack, :in)
    }

    action is {
      # We need the 'is' operator to avoid confusion with 'in site'.
      last = apply_op(stack, :is)
    }

    action interval {
      last = apply_op(stack, :interval)
      last << str_buf
      str_buf = ""
    }

    action filter {
      last = apply_op(stack, :filter)
      clause_state = :filter
    }

    action having {
      last = apply_op(stack, :having)
      clause_state = :having
    }

    action select {
      last = apply_op(stack, :select)
      clause_state = :select
    }

    action goto_expr_p {
      # remember current machine state 'cs'
      par_count += 1
      last << [:par, cs]
      stack.push last.last
      last = last.last
      fgoto expr_p;
    }

    action expr_close {
      pop_stack(stack, :par_close)
      # reset machine state 'cs'
      par_count -= 1
      cs = stack.last.delete_at(1)
      # one more time to remove [:par...] line
      stack.pop
      last = stack.last
      # closing ')' must be parsed twice
      fhold;
    }

    action goto_clause_p {
      # remember current machine state 'cs'
      clause_state = :parenthesis
      last << [:clause_par, cs]
      stack.push last.last
      last = last.last
      fgoto clause_p;
    }

    action clause_close {
      pop_stack(stack, :clause_par_close)
      clause_state = :relation
      # reset machine state 'cs'
      cs = stack.last.delete_at(1)
      # one more time to remove [:clause_par...] line
      stack.pop
      last = stack.last
      # closing ')' must be parsed twice
      fhold;
    }

    action scope {
      last = apply_op(stack, :scope)
      last << str_buf
      str_buf = ""
    }

    action offset {
      last = apply_op(stack, :offset)
    }

    action param {
      last << [:param, str_buf]
      str_buf = ""
    }

    action paginate {
      last = apply_op(stack, :paginate)
    }

    action limit {
      last = apply_op(stack, :limit)
      str_buf = ""
    }

    action order {
      last = apply_op(stack, :order)
      str_buf = ""
    }

    action group {
      last = apply_op(stack, :group)
    }

    action from_ {
      last = apply_op(stack, :from)
      clause_state = :relation
    }

    action join_clause {
      if clause_state == :relation
        last = apply_op(stack, "clause_#{str_buf}".to_sym)
        str_buf = ""
      end
    }

    action clause {
      last = insert(stack, [:clause])
    }

    action error {
      p = p - 3
      p = 0 if p < 0
      raise QueryBuilder::SyntaxError.new("Syntax error near #{data[p..-1].chomp.inspect}.")
    }

    action debug {
      print("_#{data[p..p]}")
    }

    include querybuilder "querybuilder_syntax.rl";
  }%%

    %% write data;

    def self.parse(arg)
      if arg.kind_of?(Array)
        data = "(#{arg.join(') or (')})\n"
      else
        data = "#{arg}\n"
      end
      par_count = 0
      stack = [[:query]]
      last  = stack.last
      str_buf         = ""
      clause_state = :relation
      eof = 0;
      %% write init;
      %% write exec;

      if p < pe
        p = p - 3
        p = 0 if p < 0
        raise QueryBuilder::SyntaxError.new("Syntax error near #{data[p..-2].inspect}.")
      end

      if par_count > 0
        raise QueryBuilder::SyntaxError.new("Missing closing parenthesis in #{data[0..-2].inspect}.")
      end
      stack.first
    end
  end
end
