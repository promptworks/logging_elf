require 'spec_helper'

describe LoggingElf::UncaughtExceptionsMiddleware do
  describe 'call' do
    let(:logger) { FakeLogger.new }
    let(:last_msg) { logger.logs.last }
    let(:app) { double }
    let(:env) { { test: 'test' } }
    let(:response) { 'I am the response' }
    subject do
      LoggingElf::UncaughtExceptionsMiddleware.new app, logger: logger
    end

    def act
      @returned_response = subject.call env
    end

    context 'no errors occurred' do
      before do
        app.stub(:call).with(env).and_return response
        act
      end
      it 'should not have logged anything' do
        logger.logs.count.should eq 0
      end
      specify { @returned_response.should_not be_nil }
    end

    context 'an uncaught exception is raised' do
      before do
        app.stub(:call).with(env).and_raise(StandardError)
      end

      it 'should have logged the error' do
        begin
          act
        # rubocop:disable HandleExceptions
        rescue
        # rubocop:enable HandleExceptions
        ensure
          logger.logs.count.should eq 1
          last_msg.should be_a StandardError
        end
      end

      it 're-raises the exception' do
        expect { act }.to raise_error StandardError
      end
    end

    context "an error is added to env['rack.exception']" do
      before do
        env['rack.exception'] = 'I am a sad sad exception'
        app.stub(:call).with(env).and_return response
        act
      end
      it 'should have logged the error' do
        logger.logs.count.should eq 1
        last_msg.should eq env['rack.exception']
      end
      specify { @returned_response.should_not be_nil }
    end
  end
end
