require 'spec_helper'
include Logging
include LoggingElf

describe GelfData do
  describe '.valid?'  do
    it 'should ensure validity of the data object' do
      gd = GelfData.new
      gd.version = nil
      gd.should_not be_valid
      gd.errors.count.should eq 3

      gd.host = 'host'
      gd.should_not be_valid
      gd.errors.count.should eq 2

      gd.version = '12'
      gd.should_not be_valid
      gd.errors.count.should eq 1

      gd.short_message = 'short message'
      gd.should be_valid
    end

    it 'should pull the host from the LoggingElf.config if not specified' do
      LoggingElf.configure do |config|
        config.host = 'host'
      end
      gd = GelfData.new
      gd.host.should == 'host'
    end
  end

  describe '#add_fields' do
    let(:gd) { GelfData.new }

    it 'sets a required attribute' do
      gd.add_fields(host: 'localhost')

      gd.host.should eq 'localhost'
    end

    it 'adds non-required fields to the additional_fields hash' do
      gd.add_fields(extra_field: 'extra value')

      gd.additional_fields[:_extra_field].should eq 'extra value'
    end
  end

  describe 'initialize' do
    it 'should set standard params via constructor' do
      gd = GelfData.new(
        host: 'host',
        version: '123',
        short_message: 'short_message',
        full_message: 'full_message',
        timestamp: 123,
        level: 1
      )
      gd.host.should eq 'host'
      gd.version.should eq '123'
      gd.short_message.should eq 'short_message'
      gd.full_message.should eq 'full_message'
      gd.timestamp.should eq 123
      gd.level.should eq 1
    end
  end

  describe 'from_log_event' do
    let(:event) { LogEvent.new('testing', 3, data, trace) }
    let(:trace) { nil }
    subject { GelfData.from_log_event event }

    shared_examples_for 'all gelf data' do
      specify { expect(subject.short_message).to_not be_blank }
    end

    context 'with a hash' do
      let(:data) do
        { extra_field: 'extra value', facility: 'facility' }.merge(message)
      end
      %w(message short_message).each do |field_name|
        %i(to_s to_sym).each do |field_name_format|
          context "with a #{field_name} #{field_name_format}" do
            let(:message) do
              { field_name.send(field_name_format) => 'message' }
            end
            specify do
              subject.additional_fields[:_extra_field].should eq 'extra value'
            end
            it_should_behave_like 'all gelf data'
          end
        end
      end

      context 'with no discernible message' do
        let(:message) { {} }
        specify do
          expect(subject.short_message).to eq(
            "extra_field='extra value' facility='facility'")
        end
        it_should_behave_like 'all gelf data'
      end
    end

    context 'with a string' do
      let(:data) { 'I am a string' }
      specify { expect(subject.short_message).to eq data }
    end

    context 'with an exception' do
      let(:data) { { error_object: RuntimeError.new('hi') } }
      it_should_behave_like 'all gelf data'

      context 'and a trace' do
        let(:trace) { caller }
      end
    end
  end

  describe 'to_gelf' do
    let(:gd) do
      GelfData.new(
        host: 'host',
        short_message: 'short_message',
        full_message: 'full_message',
        timestamp: 123,
        level: 1,
        line: 12,
        file: 'file',
        facility: 'facility',
        other_data: 'other_data'
      )
    end

    it 'adds a version' do
      gd.to_gelf.keys.should include(:version)
    end

    it 'prepends an underscore to some key names' do
      keys = gd.to_gelf.keys
      keys.should include(:_line, :_file, :_other_data)
      keys.should_not include(:line, :file, :other_data)
    end
  end
end
