require_relative "./common_events"

module Applicaster
  module Logger
    module Sidekiq
      class ExceptionLogger
        include Applicaster::Logger::Sidekiq
        include Applicaster::Logger::Sidekiq::CommonEvents

        def call(exception, ctxHash)
          item = ctxHash[:job]
          queue = item[:queue]

          logger.error(
            job_context(item, queue).
              deep_merge(exception_event(item, exception: exception))
          )
        end
      end
    end
  end
end
