require 'spec_helper'
require 'em-bucketer'

describe EventMachine::Bucketer::InMemory do
  it_behaves_like "a bucketer" do
    let(:bucketer) { EM::Bucketer::InMemory.new(:bucket_threshold_size => 5) }
  end
end
