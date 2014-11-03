$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require 'rspec'
require 'pry'
require 'spec_methods'
require 'em_bucketer_examples'
require 'em_bucketer_ordered_examples'

RSpec.configure do |config|
  config.order = :rand
  config.include(SpecMethods)
end
