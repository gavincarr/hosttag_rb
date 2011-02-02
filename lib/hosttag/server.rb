# Hosttag::Server class, extending Redis

require 'redis'
require 'resolv'

module Hosttag
  class Server < Redis
    def initialize(options)
      @defaults = { :server => 'hosttag', :port => 6379, :namespace => 'hosttag' }
      @defaults.merge!(options)
       
      # Check :server name resolves
      begin
        Resolv.getaddress( @defaults[:server] )
      rescue Resolv::ResolvError
        raise Resolv::ResolvError, 
          "Host '#{@defaults[:server]}' does not resolve (try --server <hostname>?)", caller
      end

      # Connect to redis
      super( :host => @defaults[:server], :port => @defaults[:port] )
    end

    def get_key(*elt)
      "#{@defaults[:namespace]}::#{elt.join(':')}"
    end
  end
end

