# Hosttag::Server class, extending Redis

require 'rubygems'
require 'redis'

module Hosttag
  class Server < Redis
    def initialize(options)
      @defaults = { :server => 'hosttag', :port => 6379, :namespace => 'hosttag' }
      @defaults.merge!(options)
      super( :host => @defaults[:server], :port => @defaults[:port] )
    end

    def get_key(*elt)
      "#{@defaults[:namespace]}::#{elt.join(':')}"
    end
  end
end

