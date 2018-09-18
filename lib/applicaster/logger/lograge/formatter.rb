module Applicaster
  module Logger
    module Lograge
      class Formatter
        def call(data)
          {
            message: message(data),
            facility: "action_controller",
            action_controller: data,
          }
        end

        def message(data)
          "[#{data[:status]}] #{data[:method]} #{data[:path]} (#{data[:controller]}##{data[:action]})"
        end
      end
    end
  end
end
