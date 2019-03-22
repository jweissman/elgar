require 'sinatra'

module Elgar
  class Server < Sinatra::Base
    get '/' do
      erb :index
    end
  end
end

if __FILE__ == $0
  Elgar::Server.run!
end
