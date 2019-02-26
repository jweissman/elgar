require 'spec_helper'
require 'elgar'

describe Elgar do
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
  end
end
