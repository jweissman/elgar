require 'elgar/version'

module Elgar
  class Sheet < Struct.new(:name)
    def write(info, at:)
      puts "---> Sheet #{@name}: write #{info} to cell #{at}"
      database[at] = info
    end

    def read(address)
      value = database[address]
      puts "---> Sheet #{@name}: read from cell at #{address}"
    end

  private

    def database
      @store ||= {}
    end

  end
end
