# http://graylog2.org/gelf#specs
# Some appenders can output to different formats, but this isn't
# one of them, so it's simplified as a result.

module LoggingElf
  class GelfData
    include Virtus.model
    include ActiveModel::Validations

    attribute :host, String
    attribute :version, String, default: '1.0'
    attribute :short_message, String
    attribute :full_message, String
    # UNIX microsecond timestamp, should be set by client!
    attribute :timestamp, Integer
    attribute :level, Integer
    # Have to set this way even though facility is deprecated
    # because gelf-rb will overwrite it otherwise
    attribute :facility, String
    attr_accessor :additional_fields
    validates :host, :version, :short_message, presence: true

    def initialize(gelf_data = {})
      super
      self.additional_fields ||= {}
      self.host ||= LoggingElf.config.host if LoggingElf.config
      return if gelf_data.nil?
      add_fields(gelf_data)
    end

    def to_gelf
      required_gelf_attributes.merge additional_fields
    end

    def required_gelf_attributes
      attributes
    end

    def self.from_log_event(log_event)
      gd = GelfData.new(level: log_event.level, facility: log_event.logger)
      case log_event.data
      when String     then gd.short_message = log_event.data
      when Hash       then add_hash_data(gd, log_event.data)
      when Exception  then add_exception_details gd, log_event.data
      end
      set_backtrace_data gd, log_event
      gd
    end

    def self.add_hash_data(gelf_data, data)
      gelf_data.add_fields(data)

      unless gelf_data.short_message
        gelf_data.short_message = data[:message] || data['message']
        if gelf_data.short_message.blank?
          gelf_data.short_message = data.map { |k, v| "#{k}='#{v}'" }.join(' ')
        end
      end
    end

    def add_fields(params_hash)
      params_hash.each do |key, value|
        if required_gelf_attributes.keys.include? key
          send("#{key}=", value)
        else
          additional_fields["_#{key}".to_sym] = value
        end
      end
    end

    def self.add_exception_details(gelf_data, error)
      gelf_data.full_message = gelf_data.short_message =
        "<#{error.class.name}> #{error.message}"
      if error.backtrace
        gelf_data.full_message << "\n\t" << error.backtrace.join("\n\t")
      end
    end

    def self.set_backtrace_data(gelf_data, event)
      gelf_data.add_fields(file: event.file) if event.file
      gelf_data.add_fields(file: event.line) if event.line
      gelf_data.add_fields(file: event.method) if event.method
    end
  end
end
