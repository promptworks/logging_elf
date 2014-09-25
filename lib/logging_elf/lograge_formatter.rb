module LoggingElf
  class LogrageFormatter
    def call(data)
      data[:message] = data[:path]
      data
    end
  end
end
