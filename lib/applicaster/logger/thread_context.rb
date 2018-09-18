module Applicaster
  module Logger
    module ThreadContext
      module_function
      KEY = self.name.to_sym

      def current
        Thread.current[KEY] ||= HashWithIndifferentAccess.new
      end

      def add(hash)
        current.merge!(hash)
      end

      def clear!
        Thread.current[KEY] = HashWithIndifferentAccess.new
      end
    end
  end
end
