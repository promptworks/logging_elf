module Logging
  module Appenders
    def self.gelf(*args)
      LoggingElf::GelfAppender.new(*args)
    end
  end
end

module LoggingElf
  class GelfAppender < ::Logging::Appender
    attr_accessor :logger

    def initialize(opts = {})
      super 'gelf', opts
      opts[:graylog_host] ||= LoggingElf.config.graylog_host
      opts[:graylog_port] ||= LoggingElf.config.graylog_port
      @logger = GELF::Logger.new(
        opts[:graylog_host], opts[:graylog_port], 'WAN')
    end

    def write(event)
      return if event.data.is_a?(String) && event.data.blank?
      message = GelfData.from_log_event event
      @logger.notify! message.to_gelf
    end
  end
end
