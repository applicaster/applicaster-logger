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
        Applicaster::Logger.setup_lograge(app) if app.config.applicaster_logger.enabled
      end

      initializer :applicaster_logger, before: :initialize_logger do |app|
        Applicaster::Logger.setup_logger(app) if app.config.applicaster_logger.enabled
      end
    end
  end
end
