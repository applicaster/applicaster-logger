require "applicaster/logger/version"
require "applicaster/logger/railtie"
require "applicaster/logger/formatter"

module Applicaster
  module Logger
    # taken from https://github.com/rails/rails/blob/master/actionpack/lib/action_controller/log_subscriber.rb
    INTERNAL_PARAMS = %w(controller action format only_path)

    def self.with_thread_data(data)
      old, Thread.current[:logger_thread_data] =
        Thread.current[:logger_thread_data], data

      yield
    ensure
      Thread.current[:logger_thread_data] = old
    end

    def self.current_thread_data
      Thread.current[:logger_thread_data] || {}
    end

    # Truncates +text+ to at most <tt>bytesize</tt> bytes in length without
    # breaking string encoding by splitting multibyte characters or breaking
    # grapheme clusters ("perceptual characters") by truncating at combining
    # characters.
    # Code taken from activesupport/lib/active_support/core_ext/string/filters.rb
    def self.truncate_bytes(text, truncate_at, omission: "...")
      omission ||= ""

      case
      when text.bytesize <= truncate_at
        text.dup
      when omission.bytesize > truncate_at
        raise ArgumentError, "Omission #{omission.inspect} is #{omission.bytesize}, larger than the truncation length of #{truncate_at} bytes"
      when omission.bytesize == truncate_at
        omission.dup
      else
        text.class.new.tap do |cut|
          cut_at = truncate_at - omission.bytesize

          text.scan(/\X/) do |grapheme|
            if cut.bytesize + grapheme.bytesize <= cut_at
              cut << grapheme
            else
              break
            end
          end

          cut << omission
        end
      end
    end
  end
end
