$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require 'rspec'
require 'pry'
require 'spec_methods'

RSpec.configure do |config|
  config.order = :rand
  config.include(SpecMethods)
end
