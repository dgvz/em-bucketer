require 'spec_helper'
require 'em-bucketer/ordered'

shared_examples "an ordered bucketer" do
  describe '#add_item' do
    it 'adds a item to the bucket' do
      EM.run do
        EM.add_timer(0.1) { fail "didn't reach EM.stop" }
        bucketer.add_item("1", {:foo => :bar}) do
          bucketer.get_bucket("1") do |bucket|
            expect(bucket).to eq([{:foo => :bar}])
            EM.stop
          end
        end
      end
    end

    it 'handles multiple buckets' do
      EM.run do
        EM.add_timer(0.1) { fail "didn't reach EM.stop" }
        bucketer.on_bucket_full do |bucket_id|
          fail "shouldn't have called full"
        end

        add_n_items_ordered(bucketer, "1", 3) do
          add_n_items_ordered(bucketer, "2", 3) do

            bucketer.get_bucket("1") do |bucket|
              expect(bucket).to eq([{:id => 0}, {:id => 1}, {:id => 2}])
              EM.stop
            end
          end
        end
      end
    end

    it 'calls on_bucket_full when a bucket fills up' do
      EM.run do
        EM.add_timer(0.1) { fail "didn't reach EM.stop" }
        bucketer.on_bucket_full do |bucket_id|
          expect(bucket_id).to eq("1")
          EM.stop
        end

        add_n_items_ordered(bucketer, "1", 5)
      end
    end
  end

  describe '#empty_bucket' do
    it 'emptys a bucket' do
      EM.run do
        EM.add_timer(0.1) { fail "didn't reach EM.stop" }
        add_n_items_ordered(bucketer, "1", 3) do
          bucketer.empty_bucket("1") do
            bucketer.get_bucket("1") do |bucket|
              expect(bucket).to eq([])
              EM.stop
            end
          end
        end
      end
    end
  end

  describe '#on_bucket_timeout' do
    it 'calls the block when the timer times out' do
      ran = false
      EM.run do
        EM.add_timer(0.05) { EM.stop }
        # Stub out the timer that the bucketer uses
        allow(EM).to receive(:add_timer) { |age, callback| callback.call }
        bucketer.on_bucket_timeout do |bucket_id|
          ran = true
          expect(bucket_id).to eq("1")
        end
        bucketer.add_item("1", :foo => :bar)
      end
      fail "didn't call timeout" unless ran
    end

    it 'doesnt call the block when the timer doesnt time out' do
      EM.run do
        EM.add_timer(0.1) { EM.stop }
        allow(EM).to receive(:add_timer)
        bucketer.on_bucket_timeout do |bucket_id|
          fail "shouldn't have called timeout"
        end
        bucketer.add_item("1", :foo => :bar)
      end
    end
  end

  describe '#pop_all' do
    it 'gets and emptys the bucket' do
      EM.run do
        EM.add_timer(0.1) { fail "didn't reach EM.stop" }
        add_n_items_ordered(bucketer, "1", 3) do

          bucketer.pop_all("1") do |bucket|
            expect(bucket).to eq([{:id => 0}, {:id => 1}, {:id => 2}])

            bucketer.get_bucket("1") do |empty_bucket|
              expect(empty_bucket).to eq([])
              EM.stop
            end
          end
        end
      end
    end
  end

  describe '#pop_count' do
    it 'gets 2 items and removes them' do
      EM.run do
        EM.add_timer(0.1) { fail "didn't reach EM.stop" }
        add_n_items_ordered(bucketer, "1", 3) do
          bucketer.get_bucket("1") do |total_bucket|
            expect(total_bucket.count).to eq(3)
            bucketer.pop_count("1", 2) do |bucket|
              expect(bucket.count).to eq(2)

              bucketer.get_bucket("1") do |remaining_bucket|
                expect(remaining_bucket.count).to eq(1)
                EM.stop
              end
            end
          end
        end
      end
    end
  end
end
