require 'spec_helper'
require 'bucketizer'

describe Bucketizer do
  let(:bucketizer) { Bucketizer::InMemory.new(:bucket_threshold_size => 5) }

  describe '#add_item' do
    it 'adds a item to the bucket' do
      ran_add = false
      ran_get = false
      bucketizer.add_item("1", "2", {:foo => :bar}) do
        ran_add = true
      end

      bucketizer.get_bucket("1") do |bucket|
        expect(bucket).to eq([{:foo => :bar}])
        ran_get = true
      end

      expect(ran_add).to eq(true)
      expect(ran_get).to eq(true)
    end

    it 'overwrites an existing item with the same id' do
      ran_get = false
      bucketizer.add_item("1", "2", {:foo => :bar})
      bucketizer.add_item("1", "2", {:bar => :foo})

      bucketizer.get_bucket("1") do |bucket|
        expect(bucket).to eq([{:bar => :foo}])
        ran_get = true
      end

      expect(ran_get).to eq(true)
    end

    it 'calls on_bucket_full when a bucket fills up' do
      ran = false
      bucketizer.on_bucket_full do |bucket_id|
        expect(bucket_id).to eq("1")
        ran = true
      end

      bucketizer.add_item("1", "1", {:foo => :bar})
      bucketizer.add_item("1", "2", {:foo => :bar})
      bucketizer.add_item("1", "3", {:foo => :bar})
      bucketizer.add_item("1", "4", {:bar => :foo})
      bucketizer.add_item("1", "5", {:bar => :foo})

      expect(ran).to eq(true)
    end
  end

  describe '#empty_bucket' do
    it 'emptys a bucket' do
      ran = false
      bucketizer.add_item("1", "1", {:foo => :bar})
      bucketizer.add_item("1", "2", {:foo => :bar})
      bucketizer.add_item("1", "3", {:foo => :bar})

      bucketizer.empty_bucket("1")

      bucketizer.get_bucket("1") do |bucket|
        expect(bucket).to eq([])
        ran = true
      end
      expect(ran).to eq(true)
    end
  end

  describe '#get_and_empty_bucket' do
    it 'gets the bucket then emptys the bucket' do
      ran_get_and_empty = false
      ran_get = false
      bucketizer.add_item("1", "1", {:foo => :bar})
      bucketizer.add_item("1", "2", {:bar => :foo})
      bucketizer.add_item("1", "3", {:boo => :far})

      bucketizer.get_and_empty_bucket("1") do |bucket|
        expect(bucket).to eq([{:foo => :bar}, {:bar => :foo}, {:boo => :far}])
        ran_get_and_empty = true
      end

      bucketizer.get_bucket("1") do |bucket|
        expect(bucket).to eq([])
        ran_get = true
      end

      expect(ran_get_and_empty).to eq(true)
      expect(ran_get).to eq(true)
    end
  end
end
