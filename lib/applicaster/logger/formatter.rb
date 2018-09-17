require 'logger'
require 'socket'
require 'time'

module Applicaster
  module Logger
    HOST = ::Socket.gethostname

    class Formatter < ::Logger::Formatter
      include LogStashLogger::TaggedLogging::Formatter

      attr_accessor :default_fields

      def initialize(options = {})
        @default_fields = options.dup
        @datetime_format = nil
      end

      def call(severity, time, progname, message)
        data = message_to_data(message).
          merge({ severity: severity, host: HOST }).
          merge(Applicaster::Logger.current_thread_data).
          reverse_merge(default_fields)

        event = LogStash::Event.new(data)
        event.timestamp = time.utc.iso8601(3)
        event.tags = current_tags
        "#{event.to_json}\n"
      end

      protected

      def message_to_data(message)
        case message
        when Hash
          message.dup
        when LogStash::Event
          message.to_hash
        when /^\{/
          JSON.parse(message).symbolize_keys rescue { message: msg2str(message) }
        else
          { message: msg2str(message) }
        end
      end
    end
  end
end
