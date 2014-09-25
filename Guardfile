# rubocop:disable Style/RegexpLiteral

guard :rspec do
  watch(%r{^lib/(.+)\.rb$}) do |m|
    ["spec/#{m[1]}_spec.rb", 'spec/integrations/entire_flow_spec.rb']
  end
  watch(%r{^spec/.+_spec\.rb$})
  watch('spec/spec_helper.rb') { 'spec' }
end
