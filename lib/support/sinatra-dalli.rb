# Based on https://github.com/JGailor/sinatra-memcache/blob/master/lib/sinatra/memcache.rb
# Modified to use dalli instead of memcache-client

require 'dalli'
require 'zlib'

module Sinatra
  module Dalli
    module Helpers

      #
      #
      #
      def cache(key, params = {}, &block)
        return block.call unless settings.cache_enable

        opts = {
          :expiry => settings.cache_default_expiry,
          :compress => settings.cache_default_compress
        }.merge(params)

        value = get(key, opts)
        return value unless block_given?

        if value
          log "Get: #{key}"
          value
        else
          log "Set: #{key}"
          set(key, block.call, opts)
        end
      rescue => e
        throw e if settings.development? || settings.show_exceptions
        block.call
      end

      #
      #
      #
      def expire(p)
        return unless settings.cache_enable

        case p
        when String
          expire_key(p)
        when Regexp
          expire_regexp(p)
        end
        true
      rescue => e
        throw e if settings.development? or settings.show_exceptions
        false
      end

      private

      def client
        settings.cache_client ||= ::Dalli::Client.new settings.cache_server,
          :namespace => settings.cache_namespace
      end

      def log(msg)
        puts "[sinatra-dalli] #{msg}" if settings.cache_logging
      end

      def get(key, opts)
        v = client.get(key, :raw => true)
        return v unless v

        v = Zlib::Inflate.inflate(v) if opts[:compress]
        Marshal.load(v)
      end

      def set(key, value, opts)
        v = Marshal.dump(value)
        v = Zlib::Deflate.deflate(v) if opts[:compress]
        client.set(key, v, opts[:expiry], :raw => true)
        value
      end

      def expire_key(key)
        client.delete(key)
        log "Expire: #{key}"
      end
    end

    def self.registered(app)
      app.helpers Dalli::Helpers

      app.set :cache_client, nil
      app.set :cache_server, "localhost:11211"
      app.set :cache_namespace, "sinatra-dalli"
      app.set :cache_enable, true
      app.set :cache_logging, true
      app.set :cache_default_expiry, 3600
      app.set :cache_default_compress, false
    end
  end

  register Dalli
end