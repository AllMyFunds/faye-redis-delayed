require 'faye/redis'

module Faye
  class RedisDelayed < Faye::Redis
    DEFAULT_EXPIRE = 60 # default expiration timeout for awaiting messages

    def subscribe(client_id, channel, &callback)
      super
      publish_awaiting_messages(channel)
    end

    def publish_awaiting_messages(channel)
      # fetch awaiting messages from redis and publish them
      @redis.lpop(@ns + "/channels#{channel}/awaiting_messages") do |json_message|
        if json_message
          message = MultiJson.load(json_message)
          publish(message, [message["channel"]], json_message)
          publish_awaiting_messages(channel)
        end
      end
    end

    def publish(message, channels, json_message = nil)
      init
      @server.debug 'Publishing message ?', message

      json_message ||= MultiJson.dump(message)
      channels     = Channel.expand(message['channel'])
      keys         = channels.map { |c| @ns + "/channels#{c}" }

      @redis.sunion(*keys) do |clients|
        if clients.empty?
          if delay_channel?(message["channel"])
            key = @ns + "/channels#{message["channel"]}/awaiting_messages"
            # store message in redis
            @redis.rpush(key, json_message)
            # Set expiration time to one minute
            @redis.expire(key, @options[:expire] || DEFAULT_EXPIRE)
          end

          if offline_channel?(message["channel"])
            @server.debug "Channel is offline: #{message["channel"]}"
            offline_callback(message)
          end
        end

        clients.each do |client_id|
          queue = @ns + "/clients/#{client_id}/messages"

          @server.debug 'Queueing for client ?: ?', client_id, message
          @redis.rpush(queue, json_message)
          @redis.publish(@message_channel, client_id)

          client_exists(client_id) do |exists|
            @redis.del(queue) unless exists
          end
        end
      end

      @server.trigger(:publish, message['clientId'], message['channel'], message['data'])
    end

    private

    def delay_channels
      @delay_channels ||= Array(@options[:delay_channels]).flatten
    end

    def delay_channel?(channel)
      delay_channels.empty? || delay_channels.any? { |pattern| pattern === channel }
    end

    def offline_channels
      @offline_channels ||= Array(@options[:offline_channels]).flatten
    end

    def offline_channel?(channel)
      offline_channels.empty? || offline_channels.any? { |pattern| pattern === channel }
    end

    def offline_callback(message)
      @server.debug "Offline callback for #{message.inspect}"
      offline_callback = @options[:offline_callback]
      offline_callback.call(message) if offline_callback.respond_to?(:call)
    end
  end
end
