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
        build_event(message, severity, time)
      end

      protected

      def build_event(message, severity, time)
        data = JSON.parse(message).symbolize_keys rescue nil if message.try(:start_with?, "{")
        data ||= message

        event =
          case data
          when LogStash::Event
            data.clone
          when Hash
            LogStash::Event.new(data.merge("@timestamp" => time))
          else
            LogStash::Event.new(message: msg2str(data), "@timestamp" => time)
          end

        event[:severity] ||= severity
        event[:host] ||= HOST

        Applicaster::Logger.current_thread_data.each do |field, value|
          event[field] = value
        end

        default_fields.each do |field, value|
          event[field] ||= value
        end

        current_tags.each do |tag|
          event.tag(tag)
        end

        # In case Time#to_json has been overridden
        if event.timestamp.is_a?(Time)
          event.timestamp = event.timestamp.iso8601(3)
        end
        "#{event.to_json}\n"
      end
    end
  end
end
