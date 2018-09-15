require 'rails/railtie'
require 'lograge'
require 'logstash-logger'

module Applicaster
  module Logger
    class Railtie < Rails::Railtie
      config.applicaster_logger = ActiveSupport::OrderedOptions.new
      config.applicaster_logger.enabled = false
      config.applicaster_logger.level = ::Logger::INFO
      config.applicaster_logger.logstash_config = { type: :stdout }
      config.applicaster_logger.application_name = Rails.application.class.parent.to_s.underscore

      initializer :applicaster_logger_lograge, before: :lograge do |app|
        setup_lograge(app) if app.config.applicaster_logger.enabled
      end

      initializer :applicaster_logger, before: :initialize_logger do |app|
        setup_logger(app) if app.config.applicaster_logger.enabled
      end

      def setup_lograge(app)
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

      def setup_logger(app)
        config = app.config.applicaster_logger
        app.config.logger = new_logger("rails_logger")
        Applicaster::Logger::Sidekiq.setup(new_logger("sidekiq")) if defined?(::Sidekiq)
        Sidetiq.logger = new_logger("sidetiq") if defined?(Sidetiq)
        Delayed::Worker.logger = new_logger("delayed") if defined?(Delayed)
      end

      def new_logger(facility)
        config = ::Rails.application.config.applicaster_logger
        LogStashLogger.new(config.logstash_config).tap do |logger|
          puts "new logger for #{facility}: #{logger}"
          logger.level = config.level
          logger.formatter = Applicaster::Logger::Formatter.new(facility: facility)
        end
      end
    end
  end
end
