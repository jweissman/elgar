require_relative './tokens'

module Elgar
  class Lexer
    include Elgar::Tokens
    def tokenize(str)
      tokens = []
      scanner = StringScanner.new(str)
      until scanner.eos?
        matched = token_matchers.detect do |matcher, entity|
          if res = scanner.scan(matcher)
            tokens.push(entity[res])
            true
          end
        end
        unless matched
          raise "Tokenization error in string #{str}: unrecognized character... (at pos=#{scanner.pos})"
        end
      end
      tokens
    end

    private
    def token_matchers
      {
        /\d+/ => Num,
        /\w+/ => Id,
        /[+*]/ => Op,
        /\(/ => LParen,
        /\)/ => RParen,
        /:/ => Colon,
      }
    end
  end
end

