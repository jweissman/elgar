require 'elgar/version'

module Elgar
  module Tokens
    class Num < Struct.new(:value); end
    class Op < Struct.new(:value); end
    class Id < Struct.new(:value); end
  end

  class Lexer
    def tokenize(str)
      tokens = []
      # consume tokens...
      scanner = StringScanner.new(str)
      until scanner.eos?
        # try to parse!!!
        if res = scanner.scan(/\d+/)
          tokens.push(Num[res.to_i])
        elsif res = scanner.scan(/\w+/)
          tokens.push(Id[res])
        elsif res = scanner.scan(/[+]/)
          tokens.push(Op[res.to_sym])
        else
          raise "Tokenization error in string #{str}: unrecognized character... (at pos=#{scanner.pos})"
        end
      end
      #
      tokens
    end
  end

  module ASTNodes
    class Int < Struct.new(:value); end

    class Add < Struct.new(:left, :right)
    end
  end

  class Parser
    # [ '=', '1', '+', '2' ] => ['+', [ 1, 2 ]]
    def tree(str)
      tokens = Lexer.new.tokenize(str)
      expr(tokens)
    end

    ### expr

    # def expr
    #   # do we have val op expr??
    #   # match(...) / consume(...)
    #   # Add[1,2]
    #   [ val, op, expr ]
    # end

    # def val #(tkns)
    #   num #(tkns)
    #   # if tkns.
    # end

    # # just give back Int?
    # def num(tkns)
    #   tkns.first.is_a?(Num) && Int[tkns.pop.value]
    # end

    # todo -- test and implement these???
    def peek; end
    def consume; end
  end

  class Formula
    def self.from_expression(input)
      ast = parse(input)
      self.new(ast)
    end

    # give back AST...
    def self.parse(input)
      Parser.new.tree(input)
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
      end
      return value
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
