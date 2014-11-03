require 'spec_helper'
require 'em-bucketer/ordered'
require 'redis'

describe EventMachine::Bucketer::Ordered::Redis do
  let(:prefix) { "test_prefix" }
  before(:each) do
    redis = Redis.new
    redis.keys("em_bucketer_ordered:#{prefix}:*").each do |k|
      redis.del(k)
    end
    redis.del("em_bucketer_ordered_known_buckets:#{prefix}")
  end

  it_behaves_like "an ordered bucketer" do
    let(:bucketer) { EM::Bucketer::Ordered::Redis.new(prefix, :bucket_threshold_size => 5) }
  end
end
