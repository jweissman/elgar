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

  describe TokenStream do
    it 'peeks/consumes' do
      tkns = TokenStream.new(tokens: ['hello', 'world'])
      expect(tkns.peek).to eq('hello')
      expect(tkns.consume).to eq('hello')
      expect(tkns.peek).to eq('world')
    end
  end

  describe Parser do


    describe 'assembles ast from tokens' do
      it 'recognizes a single number' do
        parser = Parser.new(tokens: [
          Num[1]
        ])
        expect(parser.recognize).to eq(Int[1])
      end

      it 'recognizes a literal identifier' do
        parser = Parser.new(tokens: [
          Id['xyz']
        ])
        expect(parser.recognize).to eq(CellRef['xyz'])
      end

      it 'recognizes a simple add operation' do
        parser = Parser.new(tokens: [ Num[1], Op[:+], Num[2] ])
        expect(parser.recognize).to eq(
          Add[Int[1], Int[2]]
        )
      end

      it 'recognizes repeated addition' do
        parser = Parser.new(tokens: [
          Num[1], Op[:+], Num[2], Op[:+], Num[3]
        ])
        expect(parser.recognize).to eq(
          Add[
            Add[Int[1], Int[2]],
            Int[3],
          ]
        )
      end

      it 'orders operators by precedence' do
        parser = Parser.new(
          tokens: [
            Num[1], Op[:+], Num[2], Op[:*], Num[3]
          ]
        )
        expect(parser.recognize).to eq(
          Add[
            Int[1],
            Mult[Int[2], Int[3]]
          ]
        )
      end

      it 'really orders by precedence though' do
        parser = Parser.new(
          tokens: [
            Num[1], Op[:*], Num[2], Op[:+], Num[3]
          ]
        )
        expect(parser.recognize).to eq(
          Add[
            Mult[Int[1], Int[2]],
            Int[3],
          ]
        )
      end
    end
  end

  describe Calculator do
    it 'calculates simple operations' do
      calc = Calculator.new
      expect(calc.evaluate('1+2')).to eq('3')
      expect(calc.evaluate('1+2*3')).to eq('7')
    end
  end

  describe Formula do
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

    it 'computes a standalone formula' do
      sheet = Sheet.new('the cat')
      sheet.write('=1+2', at: 'A1')
      expect(sheet.read('A1')).to eq('3')
    end

    # literal ids should NOW make it out of parsing...
    xit 'computes a simple formula with cell refs' do
      sheet = Sheet.new('felix')
      sheet.write('2', at: 'A1')
      sheet.write('3', at: 'A2')
      sheet.write('=A1+A2', at: 'A3')
      expect(sheet.read('A3')).to eq('5')
    end

    xit 'computes a formula with cell refs and function calls' do
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
