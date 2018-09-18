require 'logger'
require 'socket'
require 'time'
require 'logstash-logger'

module Applicaster
  module Logger
    HOST = ::Socket.gethostname

    class Formatter < ::Logger::Formatter
      include LogStashLogger::TaggedLogging::Formatter

      attr_accessor :default_fields

      def initialize(options = {})
        @default_fields = options.with_indifferent_access
        @datetime_format = nil
      end

      def call(severity, time, progname, message)
        data =
          default_fields.
          deep_merge(message_to_data(message)).
          merge({ severity: severity, host: HOST }).
          deep_merge(Applicaster::Logger::ThreadContext.current)

        event = LogStash::Event.new(data)
        event.timestamp = time.utc.iso8601(3)
        event.tags = current_tags
        "#{event.to_json}\n"
      end

      protected

      def message_to_data(message)
        case message
        when Hash
          message.with_indifferent_access
        when LogStash::Event
          message.to_hash.with_indifferent_access
        when /^\{/
          JSON.parse(message).with_indifferent_access rescue { message: msg2str(message) }
        else
          { message: msg2str(message) }.with_indifferent_access
        end
      end
    end
  end
end
