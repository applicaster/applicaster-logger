module Applicaster
  module Logger
    module Sidekiq
      class ThreadContext
        include Applicaster::Logger::Sidekiq

        def call(worker, item, queue)
          Applicaster::Logger::ThreadContext.add(job_context(item, queue))
          yield # Pass the torch
        ensure
          Applicaster::Logger::ThreadContext.clear!
        end
      end
    end
  end
end
