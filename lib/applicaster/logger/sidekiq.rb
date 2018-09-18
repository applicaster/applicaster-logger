require_relative "./sidekiq/middleware"
require_relative "./sidekiq/job_logger"
require_relative "./sidekiq/exception_logger"
require_relative "./sidekiq/thread_context"

module Applicaster
  module Logger
    module Sidekiq
      def self.setup(logger)
        ::Sidekiq::Logging.logger = logger
        ::Sidekiq.configure_server do |config|
          config.error_handlers.delete_if { |h| h.is_a?(::Sidekiq::ExceptionHandler::Logger) }
          ::Sidekiq.error_handlers << Applicaster::Logger::Sidekiq::ExceptionLogger.new

          config.server_middleware do |chain|
            chain.prepend Applicaster::Logger::Sidekiq::ThreadContext
          end

          if Gem::Version.new(::Sidekiq::VERSION) < Gem::Version.new("5.0")
            require 'sidekiq/api'
            config.server_middleware do |chain|
              chain.remove ::Sidekiq::Middleware::Server::Logging
              chain.add Applicaster::Logger::Sidekiq::Middleware::Server::LogstashLogging
            end
          else
            ::Sidekiq.options[:job_logger] = ::Applicaster::Logger::Sidekiq::JobLogger
          end
        end
      end

      def job_context(item, queue)
        {
          sidekiq: {
            # job ID
            jid: item['jid'],
            pid: ::Process.pid,
            # thread ID
            tid: ::Thread.current.object_id.to_s(36),
            # batch ID
            bid: item['bid'],
            # If we're using a wrapper class, like ActiveJob, use the "wrapped"
            # attribute to expose the underlying thing.
            class: (item['wrapped'] || item['class']).to_s,
            queue: queue,
            args: item['args'].inspect,
          }
        }
      end

      def logger
        ::Sidekiq.logger
      end

      def item_class_name(item)
        (item['wrapped'] || item['class']).to_s
      end
    end
  end
end
