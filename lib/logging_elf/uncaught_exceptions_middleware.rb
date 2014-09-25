module LoggingElf
  class UncaughtExceptionsMiddleware
    attr_accessor :logger

    def initialize(app, logger: nil)
      self.logger = logger
      @app = app
    end

    def call(env)
      @app.call(env).tap do |_response|
        log_any_rack_exception(env)
      end
    rescue => err
      logger.error err
      raise err
    end

    private

    def log_any_rack_exception(env)
      logger.error env['rack.exception'] if env['rack.exception']
    end
  end
end
