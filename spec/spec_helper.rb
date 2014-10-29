$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require 'rspec'
require 'pry'

RSpec.configure do |config|
  config.order = :rand
end
