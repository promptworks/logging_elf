module LoggingElf
  class << self
    attr_accessor :config

    def configure
      self.config ||= Configuration.new
      yield(config)
    end
  end

  class Configuration
    # For sending data to graylog
    attr_accessor :graylog_host, :graylog_port, :host

    # For the tracing logger
    attr_accessor :trace_hash
    def host
      @host ||= Socket.gethostname
    end
  end
end
