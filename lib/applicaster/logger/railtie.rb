require 'rails/railtie'
require 'lograge'
require 'logstash-logger'

module Applicaster
  module Logger
    class Railtie < Rails::Railtie
      DEFAULT_APP_NAME = Rails.application.class.parent.to_s.underscore

      config.applicaster_logger = ActiveSupport::OrderedOptions.new.tap do |config|
        uri = ENV["LOGSTASH_URI"]
        config.enabled = uri.present?
        config.level = ::Logger::INFO
        config.application_name = ENV.fetch("LOG_APP_NAME") { DEFAULT_APP_NAME }
        config.logstash_config = uri.present? ? { uri: uri } : { type: :stdout }
        config.logzio_token = ENV['LOGZIO_TOKEN'].presence
      end

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
          logger.level = config.level

          logger.formatter = Applicaster::Logger::Formatter.new(
            default_fields.merge({ facility: facility })
          )
        end
      end

      def default_fields
        config = ::Rails.application.config.applicaster_logger
        {
          application: config.application_name,
          environment: Rails.env.to_s
        }.merge(config.logzio_token ? { token: config.logzio_token } : {})
      end
    end
  end
end
