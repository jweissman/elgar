module Elgar
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
        elsif res = scanner.scan(/[+*]/)
          tokens.push(Op[res.to_sym])
        else
          raise "Tokenization error in string #{str}: unrecognized character... (at pos=#{scanner.pos})"
        end
      end
      #
      tokens
    end
  end
end

