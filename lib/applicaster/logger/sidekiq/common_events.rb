module Applicaster
  module Logger
    module Sidekiq
      module CommonEvents
        include Applicaster::Logger::Sidekiq

        def start_event(item)
          {
            message: "Start: #{item_class_name(item)} JID-#{item['jid']}",
            sidekiq: {
              event: "start",
              latency: ::Sidekiq::Job.new(item).latency,
            }
          }
        end

        def done_event(item, opts)
          {
            message: "Done: #{item_class_name(item)} JID-#{item['jid']}",
            sidekiq: {
              event: "done",
              runtime: opts.fetch(:runtime),
            }
          }
        end

        def exception_event(item, opts)
          exception = opts.fetch(:exception)
          {
            message: "Fail: #{item_class_name(item)} JID-#{item['jid']}",
            sidekiq: {
              event: "exception",
              exception_class: exception.class.to_s,
              exception_message: Applicaster::Logger.truncate_bytes(exception.message.to_s, 500),
            }
          }
        end
      end
    end
  end
end
