module Elgar
  module Tokens
    class Num < Struct.new(:value)
      def inspect; "Tok::Num[#{value}]"; end
    end
    class Op < Struct.new(:value)
      def inspect; "Tok::Op[#{value}]"; end
    end
    class Id < Struct.new(:value)
      def inspect; "Tok::Id[#{value}]"; end
    end
  end
end
