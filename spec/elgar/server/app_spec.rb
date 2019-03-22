ENV['APP_ENV'] = 'test'
require 'spec_helper'
# require 'net/http'
require './lib/elgar/server/app'
require 'rack/test'


describe Elgar::Server do
  include Rack::Test::Methods

  def app
    Elgar::Server
  end

  describe 'index' do
    before(:each) { get '/' }

    it 'says hello' do
      expect(last_response).to be_ok
      expect(last_response.body).to match(/hello world/)
    end

    it 'has rows and columns' do
      ('A'..'Z').each do |i|
        (1..10).each do |j|
          expect(last_response.body).to match(/#{i}#{j}/)
        end
      end
    end
  end
end
