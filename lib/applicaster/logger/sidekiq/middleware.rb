require_relative "./common_events"

module Applicaster
  module Logger
    module Sidekiq
      module Middleware
        module Server
          class LogstashLogging
            include Applicaster::Logger::Sidekiq
            include Applicaster::Logger::Sidekiq::CommonEvents

            def call(worker, item, queue)
              logger.info(start_event(item))
              start = Time.now
              yield # Pass the torch
              runtime = elapsed(start)
              logger.info(done_event(item, runtime: runtime))
            rescue Exception => exception
              logger.error(exception_event(item, exception: exception))
              raise exception
            end

            private

            def elapsed(start)
              return nil if start.nil?
              (Time.now - start).to_f.round(3)
            end
          end
        end
      end
    end
  end
end
