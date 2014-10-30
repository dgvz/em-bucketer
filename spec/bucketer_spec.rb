require 'spec_helper'
require 'bucketer'

shared_examples "a bucketer" do
  describe '#add_item' do
    it 'adds a item to the bucket' do
      EM.run do
        EM.add_timer(1) { fail "didn't reach EM.stop" }
        bucketer.add_item("1", "2", {:foo => :bar}) do
          bucketer.get_bucket("1") do |bucket|
            expect(bucket).to eq([{:foo => :bar}])
            EM.stop
          end
        end
      end
    end

    it 'overwrites an existing item with the same id' do
      EM.run do
        EM.add_timer(1) { fail "didn't reach EM.stop" }
        bucketer.add_item("1", "2", {:foo => :bar}) do
          bucketer.add_item("1", "2", {:bar => :foo}) do

            bucketer.get_bucket("1") do |bucket|
              expect(bucket).to eq([{:bar => :foo}])
              EM.stop
            end
          end
        end
      end
    end

    it 'calls on_bucket_full when a bucket fills up' do
      EM.run do
        EM.add_timer(1) { fail "didn't reach EM.stop" }
        bucketer.on_bucket_full do |bucket_id|
          expect(bucket_id).to eq("1")
          EM.stop
        end

        add_n_items(bucketer, "1", 5) {}
      end
    end
  end

  describe '#empty_bucket' do
    it 'emptys a bucket' do
      EM.run do
        EM.add_timer(1) { fail "didn't reach EM.stop" }
        add_n_items(bucketer, "1", 3) do
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

  describe '#get_and_empty_bucket' do
    it 'gets the bucket then emptys the bucket' do
      EM.run do
        EM.add_timer(1) { fail "didn't reach EM.stop" }
        add_n_items(bucketer, "1", 3) do

          bucketer.get_and_empty_bucket("1") do |bucket|
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
end
