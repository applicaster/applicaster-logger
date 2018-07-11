module Applicaster
  module Sidekiq
    class ExceptionLogger
      def call(exception, ctxHash)
        item = ctxHash[:job]
        queue = item[:queue]

        event = log_context(item, queue).merge({
          message: "Fail: #{item['class']} JID-#{item['jid']}",
          exception_class: exception.class.to_s,
          exception_message: exception.message.to_s,
        })
        logger.info(event)
      end

      private

      def log_context(item, queue)
        Applicaster::Sidekiq::JobLogger.log_context(item, queue)
      end

      def logger
        ::Sidekiq.logger
      end
    end
  end
end
