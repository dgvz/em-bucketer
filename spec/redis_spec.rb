require 'spec_helper'
require 'em-bucketer'
require 'redis'

describe EventMachine::Bucketer::Redis do
  let(:prefix) { "test_prefix" }
  before(:each) do
    redis = Redis.new
    redis.keys("em_bucketer:#{prefix}:*").each do |k|
      redis.del(k)
    end
  end

  it_behaves_like "a bucketer" do
    let(:bucketer) { EM::Bucketer::Redis.new(prefix, :bucket_threshold_size => 5) }
  end
end
