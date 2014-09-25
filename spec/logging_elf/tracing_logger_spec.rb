require 'spec_helper'
include Logging
include LoggingElf

describe LoggingElf::TracingLogger do
  let(:fake_appender) do
    # Lets us look at what was sent to the appenders
    class FakeAppender < ::Logging::Appender
      attr_accessor :logs
      def initialize(name, opts)
        super(name, opts)
        self.logs = []
      end

      def write(data)
        logs << data
      end
    end
    FakeAppender.new('test',  level: 1)
  end

  let(:trace_hash) do
    {
      browser_id: 'browser_id',
      session_id: 'session_id',
      request_method: 'request.method',
      path: 'request.path'
    }
  end

  let!(:result) do
    subject.info data
    recent_event = fake_appender.logs.last
    recent_event.nil? ? nil : recent_event.data
  end

  shared_examples_for 'log info should include trace data' do
    it 'should include the trace hash' do
      result[:browser_id].should eq trace_hash[:browser_id]
      result[:session_id].should eq trace_hash[:session_id]
      result[:request_method].should eq trace_hash[:request_method]
      result[:path].should eq trace_hash[:path]
    end
  end

  subject do
    logger = TracingLogger.new('test') { trace_hash }
    logger.appenders = fake_appender
    logger
  end

  context 'logging nil' do
    let(:data) { nil }
    specify { expect(result).to be_nil }
  end

  context 'logging a hash' do
    let(:data) do
      {
        field1: 'field1',
        field2: 'field2'
      }
    end
    it_should_behave_like 'log info should include trace data'
    it 'should include the original data as well' do
      result[:field1].should eq data[:field1]
      result[:field2].should eq data[:field2]
    end
  end

  context 'logging a string' do
    let(:data) { 'I am a Log Event' }
    specify { expect(result[:message]).to eq data }
    it_should_behave_like 'log info should include trace data'
  end

  context 'logging an exception' do
    let(:data) { RuntimeError.new 'Hi' }
    it_should_behave_like 'log info should include trace data'
    specify { result[:is_exception].should be_truthy }
    specify { result[:error_object].should eq data }
    specify { result[:backtrace].should eq data.backtrace }
    specify { result[:message].should eq 'Hi' }
    specify { result[:short_message].should eq 'Exception: Hi' }
  end

  context 'logging an unknown type' do
    let(:data) { OpenStruct.new(jeff: 'was here ') }
    it_should_behave_like 'log info should include trace data'
    it 'should still log something' do
      result[:message].should eq data.inspect
    end
  end

end
