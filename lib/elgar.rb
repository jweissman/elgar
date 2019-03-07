require 'elgar/version'
require 'elgar/tokens'
require 'elgar/lexer'

module Elgar
  class TokenStream
    def initialize(tokens:)
      @tokens = tokens
    end
    def peek; @tokens.first end
    def consume; @tokens.shift end
  end

  module ASTNodes
    class CellRef < Struct.new(:row, :column)
      def inspect; "Cell[@#{row}/#{column}]"; end
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

    def component
      p :component
      fact = factor
      the_component = nil
      while peek.is_a?(Op) && peek.value == :+
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
      while peek.is_a?(Op) && peek.value == :*
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
        Int[val]
      elsif ident?
        val = consume.value
        CellRef[val]
      else
        val = peek
        raise "Expected number/id but got #{val} [#{val.inspect} (#{val.class.name})]"
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
      p :reduce, ctx: ctx
      puts "===> WOULD REDUCE AST #{ast} IN CTX #{ctx}"
      case ast
      when Add then
        reduce(ast.left, ctx) + reduce(ast.right, ctx) #.value.to_i
      when Mult then
        reduce(ast.left, ctx) * reduce(ast.right, ctx)
      when Int then
        ast.value.to_i
      when CellRef then
        # p ctx: ctx
        raise "Implement reduce[CellRef]"
      else
        raise "Not sure what to do with node #{ast}"
      end
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
      puts "---> Sheet #{@name}: read from cell at #{address}"
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
