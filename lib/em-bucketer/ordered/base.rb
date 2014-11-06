module EventMachine::Bucketer
  module Ordered::Base
    def setup(bucket_threshold_size, bucket_max_age)
      @bucket_threshold_size = bucket_threshold_size
      @bucket_max_age = bucket_max_age
      @on_bucket_full_callbacks = []
      @on_bucket_timeout_callbacks = []
      @timers = {}
    end

    # Adds a item to the specified bucket and calls the block when it is done
    # @param bucket_id [String] the bucket id of the bucket to put the item in
    # @param item [Object] the item to be placed in the bucket
    def add_item(bucket_id, item, &blk)
      add_timer_if_first(bucket_id)
      EM::Completion.new.tap do |c|
        c.callback(&blk) if block_given?
        add_item_to_db(bucket_id, item).callback do
          c.succeed
          check_bucket_full(bucket_id)
        end.errback do |e|
          c.fail e
        end
      end
    end

    # Get at most `count` items back from a specific bucket and remove them
    # from the bucket. These should be the first `count` items you added to the
    # bucket that have not yet been removed from the bucket.
    # @param bucket_id [String] the bucket id you want the items from
    # @param count [Integer] the number of items you want from the bucket
    # @yield [Array] the first `count` items in the bucket
    def pop_count(bucket_id, count, reset_timer: true, &blk)
      reset_timer(bucket_id) if reset_timer
      EM::Completion.new.tap do |c|
        c.callback(&blk) if block_given?
        pop_count_from_db(bucket_id, count).callback do |items|
          c.succeed items
        end.errback do |e|
          c.fail e
        end
      end
    end

    # Get all items back from a specific bucket
    # and remove them from the bucket.
    #
    # @param bucket_id [String] the bucket id you want the items from
    # @yield [Array] all items in the bucket
    def pop_all(bucket_id, &blk)
      clear_timer(bucket_id)
      EM::Completion.new.tap do |c|
        c.callback(&blk) if block_given?
        pop_all_from_db(bucket_id).callback do |items|
          c.succeed items
        end.errback do |e|
          c.fail e
        end
      end
    end

    # Used to set a callback hook for when a bucket reaches the threshold size.
    # It is IMPORTANT to note that the bucket will not automatically be emptied
    # you must call empty_bucket if you want the bucket to be emptied. Also the
    # callback will be called every time a item is added until the bucket is
    # emptied.
    #
    # @yield [String] The bucket id of the full bucket
    def on_bucket_full(&blk) @on_bucket_full_callbacks << blk end

    # Used to set a callback hook for when a bucket reaches the time limit. It
    # is IMPORTANT to note that the bucket will not automatically be emptied
    # you must call empty_bucket if you want the bucket to be emptied.
    #
    # This timer is started once the bucket gets its first item and is cleared
    # only when the bucket is emptied. The callback will only be called once at
    # this time and then not again unless you empty the bucket and add
    # something again.
    #
    # @yield [String] The bucket id of the full bucket
    def on_bucket_timeout(&blk)
      @on_bucket_timeout_callbacks << blk
    end

    # Get the contents of a bucket.
    #
    # @param bucket_id [String] the bucket id of the bucket you want to get
    # @yield [Array] the items you put into the bucket
    def get_bucket(bucket_id, &blk)
      get_bucket_from_db(bucket_id, &blk)
    end

    # Empty a bucket
    #
    # @param bucket_id [String] the bucket id of the bucket you want to empty
    def empty_bucket(bucket_id, &blk)
      EM::Completion.new.tap do |c|
        c.callback(&blk) if block_given?
        empty_bucket_in_db(bucket_id).callback do
          clear_timer(bucket_id)
          c.succeed
        end.errback do |e|
          c.fail e
        end
      end
    end

    private

    def get_and_remove_iterator(bucket_id, count, values, completion)
      proc do |tuple, iter|
        key, val = tuple[0], tuple[1]
        if values.count < count
          values << val
          iter.next
        else
          add_item(bucket_id, key, val).callback do
            iter.next
          end.errback do |e|
            completion.fail e
          end
        end
      end
    end

    def bucket_full?(bucket_id, &blk)
      bucket_size_from_db(bucket_id).callback do |size|
        blk.call size >= @bucket_threshold_size
      end
    end

    def bucket_empty?(bucket_id, &blk)
      bucket_size_from_db(bucket_id).callback do |size|
        blk.call size == 0
      end
    end

    def check_bucket_full(bucket_id)
      bucket_full?(bucket_id) do |is_full|
        if is_full
          @on_bucket_full_callbacks.each do |callback|
            callback.call bucket_id
          end
        end
      end
    end

    def add_timer_if_first(bucket_id)
      return unless @bucket_max_age
      @timers[bucket_id] ||= EM::Timer.new(@bucket_max_age, timeout_callback(bucket_id))
    end

    def timeout_callback(bucket_id)
      proc do |bar|
        @on_bucket_timeout_callbacks.each do |callback|
          callback.call bucket_id
        end
      end
    end

    def clear_timer(bucket_id)
      return unless @bucket_max_age
      timer = @timers.delete(bucket_id)
      timer.cancel if timer
    end

    def reset_timer(bucket_id)
      return unless @bucket_max_age
      clear_timer(bucket_id)
      bucket_empty?(bucket_id) do |is_empty|
        @timers[bucket_id] = EM::Timer.new(@bucket_max_age, timeout_callback(bucket_id)) unless is_empty
      end
    end
  end
end
