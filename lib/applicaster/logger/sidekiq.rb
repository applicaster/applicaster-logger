require_relative "./sidekiq/middleware"
require_relative "./sidekiq/job_logger"
require_relative "./sidekiq/exception_logger"

module Applicaster
  module Logger
    module Sidekiq
      def self.setup(logger)
        if defined?(::Sidekiq)
          ::Sidekiq.configure_server do |config|
            config.error_handlers.delete_if { |h| h.is_a?(::Sidekiq::ExceptionHandler::Logger) }
            ::Sidekiq.error_handlers << Applicaster::Logger::Sidekiq::ExceptionLogger.new

            if Gem::Version.new(::Sidekiq::VERSION) < Gem::Version.new("5.0")
              require 'sidekiq/api'
              config.server_middleware do |chain|
                chain.remove ::Sidekiq::Middleware::Server::Logging
                chain.add Applicaster::Logger::Sidekiq::Middleware::Server::LogstashLogging
              end
            else
              ::Sidekiq::Logging.logger = logger
              ::Sidekiq.options[:job_logger] = ::Applicaster::Logger::Sidekiq::JobLogger
            end
          end
        end
      end
    end
  end
end
