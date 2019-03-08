module Elgar
  module Tokens
    class Token < Struct.new(:value)
      def inspect; "#{self.class.name}[tkn='#{value}']" end
    end

    class Num < Token; end
    class Op < Token; end
    class Id < Token; end
    class LParen < Token; end
    class RParen < Token; end
    class Colon < Token; end
    class Comma < Token; end
  end
end
