require 'pry'
require 'elgar/version'
require 'elgar/tokens'
require 'elgar/lexer'

module Elgar
  class TokenStream
    def initialize(tokens:)
      @tokens = tokens
    end
    def peek; @tokens.first end
    def peek_next; @tokens[1] end
    def consume; @tokens.shift end
  end

  module ASTNodes
    class CellRef < Struct.new(:row, :column)
      def inspect; "Cell[@#{row}-#{column}]"; end
    end

    class CellRange < Struct.new(:range_start, :range_end)
      def inspect; "CellRange[#{range_start}, #{range_end}]" end
    end

    class Int  < Struct.new(:value)
      def inspect; "Int[#{value}]"; end
    end
    class Add  < Struct.new(:left, :right)
      def inspect; "Add[#{left.inspect}, #{right.inspect}]"; end
    end
    class Mult < Struct.new(:left, :right)
      def inspect; "Mult[#{left.inspect}, #{right.inspect}]"; end
    end

    class Arglist < Struct.new(:args); end
    class Funcall < Struct.new(:func, :arglist); end
  end

  class Parser
    def initialize(tokens:)
      @stream = TokenStream.new(tokens: tokens)
    end

    def recognize
      expression
    end

    private
    def expression
      p :expr
      result = component || factor || value
      if !epsilon?
        raise "Did not fully recognize token stream; parsed: #{result}"
      end
      result
    end

    def funcall
      p :funcall
      if ident? && peek_next.is_a?(LParen)
        id = consume
        args = arglist
        Funcall[id, args]
      end
    end

    def arglist
      args = []
      if peek.is_a?(LParen)
        _lparen = consume
        args.push(value)
        while !consume.is_a?(RParen)
          args.push(value)
          if peek.is_a?(Comma)
            _comma = consume
          end
        end
        Arglist[args]
      end
    end

    def component
      p :component
      fact = factor
      the_component = nil
      while peek.is_a?(Op) && peek.value == '+'
        left = the_component || fact
        consume # mult
        the_component = Add[left, factor]
      end
      the_component || fact
    end

    def factor
      p :factor
      val = value
      the_factor = nil
      while peek.is_a?(Op) && peek.value == '*'
        left = the_factor || val
        consume # add
        the_factor = Mult[left, value]
      end
      the_factor || val
    end

    def op?
      peek.is_a?(Op)
    end

    def value
      p :value
      val = nil
      if num?
        val = consume.value
        Int[val.to_i]
      elsif ident?
        if peek_next.is_a?(LParen) # funcall?
          funcall
        elsif peek_next.is_a?(Colon) # cell range
          lval = cell_ref
          _colon = consume
          unless ident?
            raise "Expected id to close cell range but saw #{peek.value}"
          end
          rval = cell_ref
          CellRange[lval, rval]
        else
          cell_ref
        end
      else
        val = peek
        raise "Expected number/id but got #{val} [#{val.inspect} (#{val.class.name})]"
      end
    end

    def cell_ref
      if ident?
        val = consume.value
        alpha_num = /([a-zA-Z]+)([0-9]+)/
        matches = val.match(alpha_num)
        row, column = matches[1,2]
        CellRef[row, column]
      end
    end

    def value?
      num? || ident?
    end

    def num?
      peek.is_a?(Num)
    end

    def ident?
      peek.is_a?(Id)
    end

    def epsilon?
      peek.nil?
    end

    def peek; @stream.peek end
    def peek_next; @stream.peek_next end
    def consume; @stream.consume end
  end

  class Calculator
    def evaluate(str, ctx={})
      tokens = Lexer.new.tokenize(str)
      tree = Parser.new(tokens: tokens).recognize
      reduce(tree, ctx).to_s
    end

    private

    def reduce(ast, ctx={})
      case ast
      when Add then
        reduce(ast.left, ctx).to_i + reduce(ast.right, ctx).to_i
      when Mult then
        reduce(ast.left, ctx).to_i * reduce(ast.right, ctx).to_i
      when Int then
        ast.value.to_i
      when CellRef then
        # p ctx: ctx
        # raise "Implement reduce[CellRef]"
        ctx.read([ast.row, ast.column].join)
      when CellRange then
        start, finish = *ast
        cell_names = []
        if start.column == finish.column
          # number is same, letter is different
          letters = start.row.upto(finish.row)
          cell_names = letters.map{ |l| "#{l}#{start.column}" }
        elsif start.row == finish.row
          row = start.row
          # ...
          cell_names = [row, start.column].join.upto([row, finish.column].join)
        else
          raise "Cell range must be linear"
        end

        # binding.pry
        range_elems = cell_names.map do |address|
          ctx.read(address)
        end
        # binding.pry
        range_elems
      when Funcall then
        fn_name = ast.func.value.to_sym
        args = ast.arglist.args.map do |arg|
          reduce(arg, ctx)
        end
        if builtins.has_key?(fn_name)
          puts "---> Call #{fn_name} with args: #{args}"
          builtins[fn_name].call(*args.flatten.map(&:to_i))
        else
          raise "No such fn with name #{fn_name}"
        end
      else
        raise "Calculator#reduce: Implement reduce for #{ast.class.name}"
      end
    end

    def builtins
      {
        pow: ->(x,y) { x ** y },
        sum: ->(*vals) { vals.inject(&:+) }
      }
    end

  end

  class Formula
    def initialize(string)
      @input = string
      if !@input.start_with?('=')
        raise "Input string #{string} is not a valid formula! (Formulas start with equals-sign [=])"
      else
        # strip out leading =...
        @input[0] = ''
      end
    end

    def compute(ctx)
      p :compute, ctx: ctx
      # @result ||=
      calculator.evaluate(@input, ctx)
    end

    def self.from_expression(input_string)
      new(input_string)
    end

    private

    def calculator
      @calc ||= Calculator.new
    end
  end

  class Sheet < Struct.new(:name)
    def write(info, at:)
      puts "---> Sheet #{@name}: write #{info} to cell #{at}"
      database[at] = info
    end

    def read(address)
      value = database[address]
      puts "---> Sheet #{@name}: read from cell at #{address} => #{value}"
      if value.start_with?('=')
        # raise "Would compute formula: #{value}"
        compute_formula(value)
      else
        value
      end
    end

    private

    def database
      @store ||= {}
    end

    def compute_formula(value)
      # parse and compute...
      Formula.from_expression(value).compute(self)
    end
  end
end
