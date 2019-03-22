require 'spec_helper'
require 'elgar'

include Elgar::Tokens
include Elgar::ASTNodes

describe Elgar do

  describe TokenStream do
    it 'peeks/consumes' do
      tkns = TokenStream.new(tokens: ['hello', 'world'])
      expect(tkns.peek).to eq('hello')
      expect(tkns.consume).to eq('hello')
      expect(tkns.peek).to eq('world')
    end
  end
end


