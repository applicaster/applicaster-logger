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

      if defined?(::Sidekiq)
        ::Sidekiq.configure_server do |config|
          config.error_handlers.delete_if { |h| h.is_a?(::Sidekiq::ExceptionHandler::Logger) }
          ::Sidekiq.error_handlers << Applicaster::Sidekiq::ExceptionLogger.new

          if Gem::Version.new(::Sidekiq::VERSION) < Gem::Version.new("5.0")
            require 'sidekiq/api'
            config.server_middleware do |chain|
              chain.remove ::Sidekiq::Middleware::Server::Logging
              chain.add Applicaster::Sidekiq::Middleware::Server::LogstashLogging
            end
          else
            logger = LogStashLogger.new(logstash_config)
            logger.level = app.config.applicaster_logger.level
            logger.formatter = Applicaster::Logger::Formatter.new(facility: "sidekiq")
            ::Sidekiq::Logging.logger = logger
            ::Sidekiq.options[:job_logger] = ::Applicaster::Sidekiq::JobLogger
          end
        end
      end

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
  end
end
