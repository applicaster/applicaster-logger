module Applicaster
  module Sidekiq
    class JobLogger
      def call(item, queue)
        puts "JobLogger"
        start = Time.now
        event = log_context(item, queue).merge({
          message: "Start: #{item['class']} JID-#{item['jid']}",
        })
        logger.info(event)
        yield
        event = log_context(item, queue).merge({
          message: "Done: #{item['class']} JID-#{item['jid']}",
        })
        event[:sidekiq][:duration] = elapsed(start)
        logger.info(event)
      end

      private

      def elapsed(start)
        (Time.now - start).round(3)
      end

      def logger
        ::Sidekiq.logger
      end

      def log_context(item, queue)
        self.class.log_context(item, queue)
      end

      def self.sidekiq_context
        ::Thread.current[:sidekiq_context]
      end

      def self.log_context(item, queue)
        {
          sidekiq: {
            jid: item['jid'],
            context: sidekiq_context,
            worker: item['class'].to_s,
            queue: queue,
            args: item['args'].inspect,
          }
        }
      end
    end
  end
end
