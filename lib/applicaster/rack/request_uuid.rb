module Applicaster
  module Rack
    class RequestUuid
      def initialize(app)
        @app = app
      end

      def call(env)
        request = ActionDispatch::Request.new(env)

        Applicaster::Logger.with_request_uuid(request.uuid) do
          @app.call(env)
        end
      end
    end
  end
end
