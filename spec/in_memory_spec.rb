require 'spec_helper'
require 'bucketer'

describe Bucketer::InMemory do
  it_behaves_like "a bucketer" do
    let(:bucketer) { Bucketer::InMemory.new(:bucket_threshold_size => 5) }
  end
end
