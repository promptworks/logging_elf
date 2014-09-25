ENV['RAILS_ENV'] ||= 'test'

require 'logging_elf'
support_files = Dir[File.join(
  File.expand_path('../../spec/support/**/*.rb', __FILE__)
)]
support_files.each { |f| require f }

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.order = :random

  config.before(:each) do
    LoggingElf.config = nil
  end
end
