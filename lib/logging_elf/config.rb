module LoggingElf
  class << self
    attr_accessor :config

    def configure
      self.config ||= Configuration.new
      yield(config)
    end
  end

  class Configuration
    attr_accessor :graylog_host, :graylog_port, :trace_hash, :host
  end
end
