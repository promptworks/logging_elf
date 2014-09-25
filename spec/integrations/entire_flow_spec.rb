require 'spec_helper'

class FakeGelfNotifier
  attr_accessor :logs

  def initialize
    self.logs = []
  end

  def notify!(data)
    logs << data
  end
end

describe 'Tracing all the way through' do
  let(:notifier) do
    # Lets us look at what was sent to the appenders
    FakeGelfNotifier.new
  end

  let(:trace_hash) { { browser_id: 'browser_id' } }

  let(:gelf_data_hash) { notifier.logs.last }

  before do
    LoggingElf.configure do |config|
      config.trace_hash = -> { trace_hash }
      config.host = 'host'
    end

    logger = LoggingElf::TracingLogger.new("test")

    appender = Logging::Appenders.gelf
    appender.logger = notifier

    logger.add_appenders(appender)

    logger.info log_subject
  end

  shared_examples_for 'gelf data output' do
    let(:reconstituted_gelf_data) do
      gelf_data_hash.select { |k, _| k.to_s.start_with?('_') }.each do |k, _|
        gelf_data_hash["#{k.slice(1..-1)}"] = gelf_data_hash.delete k
      end
      LoggingElf::GelfData.new gelf_data_hash
    end

    specify { expect(reconstituted_gelf_data).to be_valid }
  end

  describe 'logging a string' do
    let(:log_subject) { 'string message' }
    it_should_behave_like 'gelf data output'
    specify { expect(gelf_data_hash[:short_message]).to eq 'string message' }
    specify { expect(gelf_data_hash[:_browser_id]).to eq 'browser_id' }
  end

  describe 'logging a hash' do
    let(:log_subject) { { foo: 'bar' } }
    it_should_behave_like 'gelf data output'
  end

  describe 'logging an exception' do
    let(:log_subject) { RuntimeError.new 'Boom' }
    it_should_behave_like 'gelf data output'
  end

end
