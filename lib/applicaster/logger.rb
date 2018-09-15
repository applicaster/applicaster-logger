require "applicaster/logger/version"
require "applicaster/logger/railtie"
require "applicaster/logger/formatter"

module Applicaster
  module Logger
    # taken from https://github.com/rails/rails/blob/master/actionpack/lib/action_controller/log_subscriber.rb
    INTERNAL_PARAMS = %w(controller action format only_path)

    def self.setup_lograge(app)
      app.config.lograge.enabled = true
      app.config.lograge.formatter = Lograge::Formatters::Logstash.new
      app.config.lograge.custom_options = lambda do |event|
        {
          params: event.payload[:params].except(*INTERNAL_PARAMS).inspect,
          facility: "action_controller",
          custom_params: event.payload[:custom_params],
        }
      end

      app.middleware.insert_after ActionDispatch::RequestId,
        Applicaster::Rack::RequestData
    end

    def self.setup_logger(app)
      logstash_config = app.config.applicaster_logger.logstash_config

      app.config.logger = LogStashLogger.new(logstash_config)
      app.config.logger.level = app.config.applicaster_logger.level
      app.config.logger.formatter =
        Applicaster::Logger::Formatter.new(facility: "rails_logger")

      if defined?(Delayed)
        Delayed::Worker.logger = LogStashLogger.new(logstash_config)
        Delayed::Worker.logger.level = app.config.applicaster_logger.level
        Delayed::Worker.logger.formatter =
          Applicaster::Logger::Formatter.new(facility: "delayed_job")
      end

      logger = LogStashLogger.new(logstash_config)
      logger.level = app.config.applicaster_logger.level
      logger.formatter = Applicaster::Logger::Formatter.new(facility: "sidekiq")
      Applicaster::Logger::Sidekiq.setup(logger)

      if defined?(Sidetiq)
        Sidetiq.logger = LogStashLogger.new(logstash_config)
        Sidetiq.logger.level = app.config.applicaster_logger.level
        Sidetiq.logger.formatter =
          Applicaster::Logger::Formatter.new(facility: "sidetiq")
      end
    end

    def self.with_thread_data(data)
      old, Thread.current[:logger_thread_data] =
        Thread.current[:logger_thread_data], data

      yield
    ensure
      Thread.current[:logger_thread_data] = old
    end

    def self.current_thread_data
      Thread.current[:logger_thread_data] || {}
    end

    # Truncates +text+ to at most <tt>bytesize</tt> bytes in length without
    # breaking string encoding by splitting multibyte characters or breaking
    # grapheme clusters ("perceptual characters") by truncating at combining
    # characters.
    # Code taken from activesupport/lib/active_support/core_ext/string/filters.rb
    def self.truncate_bytes(text, truncate_at, omission: "...")
      omission ||= ""

      case
      when text.bytesize <= truncate_at
        text.dup
      when omission.bytesize > truncate_at
        raise ArgumentError, "Omission #{omission.inspect} is #{omission.bytesize}, larger than the truncation length of #{truncate_at} bytes"
      when omission.bytesize == truncate_at
        omission.dup
      else
        text.class.new.tap do |cut|
          cut_at = truncate_at - omission.bytesize

          text.scan(/\X/) do |grapheme|
            if cut.bytesize + grapheme.bytesize <= cut_at
              cut << grapheme
            else
              break
            end
          end

          cut << omission
        end
      end
    end
  end
end
