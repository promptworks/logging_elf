class FakeLogger
  attr_accessor :logs
  def initialize
    @logs = []
  end

  def debug(obj)
    logs << obj
  end

  alias_method :info, :debug
  alias_method :warn, :debug
  alias_method :error, :debug
  alias_method :fatal, :debug
end
