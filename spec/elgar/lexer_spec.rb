require 'spec_helper'
require 'elgar/lexer'

include Elgar::Tokens

describe Lexer do
  subject(:lex) { described_class.new }
  context 'individual tokens' do
    it 'tokenizes a number' do
      expect(lex.tokenize('1')).to eq([Num['1']])
    end

    it 'tokenizes an operation' do
      expect(lex.tokenize('+')).to eq([Op['+']])
    end

    it 'tokenizes a literal identifier' do
      expect(lex.tokenize('a1')).to eq([Id['a1']])
    end

    it 'tokenizes parentheses' do
      expect(lex.tokenize('(')).to eq([LParen['(']])
      expect(lex.tokenize(')')).to eq([RParen[')']])
    end

    it 'tokenizes colon' do
      expect(lex.tokenize(':')).to eq([Colon[':']])
    end
  end

  context 'complex expressions' do
    it 'tokenizes a binary op with numbers and identifiers' do
      expect(lex.tokenize('1+a2')).to eq([
        Num['1'],
        Op['+'],
        Id['a2']
      ])
    end

    it 'tokenizes a funcall with cell range' do
      expect(lex.tokenize('sum(a1:a2)')).to eq([
        Id['sum'],
        LParen['('],
        Id['a1'],
        Colon[':'],
        Id['a2'],
        RParen[')'],
      ])
    end
  end
end

