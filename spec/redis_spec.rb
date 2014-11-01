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
    redis.del("em_bucketer_known_buckets:#{prefix}")
  end

  it_behaves_like "a bucketer" do
    let(:bucketer) { EM::Bucketer::Redis.new(prefix, :bucket_threshold_size => 5) }
  end

  it 'will set timers for existing buckets on startup' do
    EM.run do
      EM.add_timer(0.1) { EM.stop }
      allow(EM).to receive(:add_timer).with(anything).and_yield
      bucketer = EM::Bucketer::Redis.new(prefix, :bucket_threshold_size => 5)
      bucketer.add_item("1", "2", :foo => :bar).callback do
        bucketer.add_item("3", "4", :foo => :bar).callback do

          expect(EM).to receive(:add_timer).with(3600).twice
          bucketer = EM::Bucketer::Redis.new(prefix, :bucket_threshold_size => 5)
        end
      end
    end
  end
end
