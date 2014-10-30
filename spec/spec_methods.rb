module SpecMethods
  def add_n_items(bucketer, bucket, n, &blk)
    worker = proc do |i, iter|
      bucketer.add_item(bucket, i.to_s, {:id => i}) do
        iter.next
      end
    end
    EM::Iterator.new(0...n).each(worker, blk)
  end
end
