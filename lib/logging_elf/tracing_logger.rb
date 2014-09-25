module LoggingElf
  class TracingLogger
    extend Forwardable
    def_delegators :@logger, *[
      :<<, :<=>, :_dump_configuration, :_meta_eval, :_setup, :add,
      :add_appenders, :additive, :additive=, :appenders, :appenders=,
      :clear_appenders, :config, :formatter, :inspect, :level, :level=, :name,
      :parent, :remove_appenders, :root, :trace, :trace=, :write
    ]

    Logging.init

    Logging::LEVELS.keys.each do |name|
      def_delegator :@logger, :"#{name}?"

      define_method name do |data = nil|
        log_level(name, data)
      end
    end

    def log_level(name, data)
      @logger.public_send(name, append_trace_info(data)) unless data.nil?
    rescue => err
      p err
      pp err.backtrace
    end

    def initialize(logger, &trace_hash)
      @logger = Logging::Logger.new logger if logger.is_a? String
      self.trace_hash = if block_given?
                          trace_hash
                        elsif LoggingElf.config.trace_hash
                          LoggingElf.config.trace_hash
                        else
                          fail 'TracingLogger cannot be created with no' \
                            ' mechanism for appending trace data'
                        end
    end

    attr_writer :trace_hash
    def trace_hash
      if @trace_hash.respond_to?(:call)
        @trace_hash.call
      elsif @trace_hash
        @trace_hash
      else
        {}
      end
    end

    def exception_data(data)
      {
        error_object: data,
        backtrace: data.backtrace,
        short_message: "Exception: #{data.message}",
        message: data.message,
        is_exception: true
      }
    end

    def default_data(data)
      {
        short_message: 'Unknown thing to log',
        message: data.inspect
      }
    end

    def append_trace_info(data)
      data = case data
             when Hash then data
             when Exception then exception_data(data)
             when String then { message: data }
             when nil then return
             else
               default_data(data)
             end
      data.merge(trace_hash)
    end
  end
end
