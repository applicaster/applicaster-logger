module Applicaster
  module Logger
    module Rack
      class ThreadContext
        def initialize(app)
          @app = app
        end

        def call(env)
          @app.call(env)
        ensure
          Applicaster::Logger::ThreadContext.clear!
        end
      end
    end
  end
end
