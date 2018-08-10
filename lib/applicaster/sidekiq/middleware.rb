module Applicaster
  module Sidekiq
    module Middleware
      module Server
        class LogstashLogging

          def call(worker, item, queue)
            ::Sidekiq::Logging.with_context("#{worker.class.to_s} JID-#{item['jid']}") do
              begin
                logger.info(filter_fields({
                  message: "Start: #{worker.class.to_s} JID-#{item['jid']}",
                  jid: item['jid'],
                  pid: pid,
                  tid: tid,
                  context: context,
                  worker: worker.class.to_s,
                  queue: queue,
                  args: item['args'].inspect,
                  latency: ::Sidekiq::Job.new(::Sidekiq.dump_json(item)).latency,
                  memory: memory
                }))

                start = Time.now

                yield # Pass the torch

                logger.info(filter_fields({
                  message: "Done: #{worker.class.to_s} JID-#{item['jid']}",
                  jid: item['jid'],
                  pid: pid,
                  tid: tid,
                  context: context,
                  worker: worker.class.to_s,
                  queue: queue,
                  args: item['args'].inspect,
                  runtime: elapsed(start),
                  memory: memory
                }))
              rescue Exception => e
                logger.error(filter_fields({
                  message: "Fail: #{worker.class.to_s} JID-#{item['jid']}",
                  jid: item['jid'],
                  pid: pid,
                  tid: tid,
                  context: context,
                  worker: worker.class.to_s,
                  queue: queue,
                  args: item['args'].inspect,
                  runtime: elapsed(start),
                  exception_class: e.class.to_s,
                  exception_message: Applicaster::Logger.truncate_bytes(e.message.to_s, 500),
                  memory: memory
                }))

                raise e
              ensure
                logger.device.close
              end
            end
          end

          def logger
            @logger ||=
              begin
                applicaster_logger = ::Rails.application.config.applicaster_logger
                logger = LogStashLogger.new(applicaster_logger.logstash_config)
                logger.level = applicaster_logger.sidekiq_log_level || applicaster_logger.level
                logger.formatter = Applicaster::Logger::Formatter.new(facility: "sidekiq")
                logger
              end
          end

          private

          def pid
            ::Process.pid
          end

          def tid
            ::Thread.current.object_id.to_s(36)
          end

          def context
            ::Thread.current[:sidekiq_context]
          end

          def memory
            `ps -o rss= -p #{::Process.pid}`.chomp.to_i
          end

          def elapsed(start)
            return nil if start.nil?
            (Time.now - start).to_f.round(3)
          end

          def filter_fields(data)
            data.each do |key, val|
              if val.is_a?(String) && val.length > 32766 # max message length
                data[key] = "[omitted; length = #{val.length}, max = 32766]"
              end
            end

            data
          end
        end
      end
    end
  end
end
