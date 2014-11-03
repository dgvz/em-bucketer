require 'spec_helper'
require 'em-bucketer/ordered'

describe EventMachine::Bucketer::Ordered::InMemory do
  it_behaves_like "an ordered bucketer" do
    let(:bucketer) { EM::Bucketer::Ordered::InMemory.new(:bucket_threshold_size => 5) }
  end
end
