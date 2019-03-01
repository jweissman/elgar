require 'spec_helper'
require 'elgar'

include Elgar::Tokens
include Elgar::ASTNodes

describe Elgar do
  describe Lexer do
    it 'tokenizes' do
      lex = Lexer.new()
      expect(lex.tokenize('1+a2')).to eq([
        Num[1],
        Op[:+],
        Id['a2']
      ])
    end
  end

  describe Parser do
    xit 'assembles ast' do
      parser = Parser.new
      expect(parser.tree('1+2')).to eq(Add[1,2])
      expect(parser.tree('1+2+3')).to eq(Add[Add[1,2],3])
    end
  end

  xdescribe Formula do
    it 'computes simple arith' do
      fake_sheet = double(Sheet)
      fx = Formula.from_expression('=1+2')
      expect(fx.compute(fake_sheet)).to eq('3')
    end
  end

  describe Sheet do
    it 'has a name' do
      sheet = Sheet.new('cats')
      expect(sheet.name).to eq('cats')
    end

    it 'has data in rows and columns' do
      sheet = Sheet.new('felis cattus')
      sheet.write('hello', at: 'A1')
      expect(sheet.read('A1')).to eq('hello')
    end

    xit 'computes a formula' do
      sheet = Sheet.new('felis cattus')
      sheet.write('name', at: 'A1')
      sheet.write('age', at: 'A2')

      sheet.write('alison', at: 'B1')
      sheet.write('1', at: 'B2')

      sheet.write('ari', at: 'C1')
      sheet.write('2', at: 'C2')

      sheet.write('total', at: 'F1')
      sheet.write('=sum(B2:E2)', at: 'F2')

      expect(sheet.read('F2')).to eq('3')
    end
  end
end
