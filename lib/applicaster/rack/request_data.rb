module Applicaster
  module Rack
    class RequestData
      def initialize(app)
        @app = app
      end

      def call(env)
        Applicaster::Logger.with_thread_data(request_data(env)) do
          @app.call(env)
        end
      end

      def request_data(env)
        request = ActionDispatch::Request.new(env)
        {
          request_uuid: request.uuid,
          remote_ip: request.remote_ip,
          request_host: request.host,
        }
      end
    end
  end
end
