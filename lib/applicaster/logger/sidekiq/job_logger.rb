require_relative "./common_events"

module Applicaster
  module Logger
    module Sidekiq
      class JobLogger
        include Applicaster::Logger::Sidekiq
        include Applicaster::Logger::Sidekiq::CommonEvents

        def call(item, queue)
          start = Time.now
          logger.info(job_context(item, queue).deep_merge(start_event(item)))
          yield
          runtime = elapsed(start)
          logger.info(job_context(item, queue).deep_merge(done_event(item, runtime: runtime)))
        end

        private

        def elapsed(start)
          (Time.now - start).round(3)
        end
      end
    end
  end
end
