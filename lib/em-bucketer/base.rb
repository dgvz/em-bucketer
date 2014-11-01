module EventMachine::Bucketer
  module Base
    def setup(bucket_threshold_size, bucket_max_age)
      @bucket_threshold_size = bucket_threshold_size
      @bucket_max_age = bucket_max_age
      @buckets = {}
      @on_bucket_full_callbacks = []
      @on_bucket_timeout_callbacks = []
      @buckets_with_timers = Set.new
    end

    # Adds a item to the specified bucket and
    # calls the block when it is done
    #
    # @param bucket_id [String] the bucket id of
    # the bucket to put the item in
    # @param item_id [String] the item_id
    # of the item (used to ensure uniqueness
    # within a bucket)
    # @param item [Object] the item to be
    # placed in the bucket
    def add_item(bucket_id, item_id, item, &blk)
      add_timer_if_first(bucket_id)
      EM::Completion.new.tap do |c|
        c.callback(&blk) if block_given?
        add_bucket_to_db(bucket_id, item_id, item).callback do
          c.succeed
        end.errback do |e|
          c.fail e
        end
        check_bucket_full(bucket_id)
      end
    end

    # Used to set a callback hook for when a bucket
    # reaches the threshold size. It is IMPORTANT
    # to note that the bucket will not automatically
    # be emptied you must call empty_bucket if you
    # want the bucket to be emptied. Also the callback
    # will be called every time a item is added
    # until the bucket is emptied.
    #
    # @yield [String] The bucket id of the full bucket
    def on_bucket_full(&blk)
      @on_bucket_full_callbacks << blk
    end

    # Used to set a callback hook for when a bucket
    # reaches the time limit. It is IMPORTANT
    # to note that the bucket will not automatically
    # be emptied you must call empty_bucket if you
    # want the bucket to be emptied.
    #
    # This timer is started once the bucket gets its
    # first item and is cleared only when the
    # bucket is emptied. The callback will only be
    # called once at this time and then not again
    # unless you empty the bucket and add something
    # again.
    #
    # @yield [String] The bucket id of the full bucket
    def on_bucket_timeout(&blk)
      @on_bucket_timeout_callbacks << blk
    end

    # Get the contents of a bucket.
    #
    # @param bucket_id [String] the bucket id
    # of the bucket you want to get
    # @yield [Array] the items you put
    # into the bucket
    def get_bucket(bucket_id, &blk)
      EM::Completion.new.tap do |c|
        c.callback(&blk) if block_given?
        get_bucket_from_db(bucket_id).callback do |bucket|
          c.succeed bucket.values
        end.errback do |e|
          c.fail e
        end
      end
    end

    # Get the contents of a bucket then empty it
    #
    # @param bucket_id [String] the bucket id
    # of the bucket you want to get
    # @yield [Array] the items you put
    # into the bucket
    def get_and_empty_bucket(bucket_id, &blk)
      EM::Completion.new.tap do |c|
        c.callback(&blk) if block_given?
        get_bucket(bucket_id).callback do |contents|
          empty_bucket(bucket_id).callback do
            c.succeed contents
          end.errback do |e|
            c.fail e
          end
        end.errback do |e|
          c.fail e
        end
      end
    end

    # Empty a bucket
    #
    # @param bucket_id [String] the bucket id
    # of the bucket you want to empty
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

    def bucket_full?(bucket_id, &blk)
      bucket_size_from_db(bucket_id).callback do |size|
        blk.call size >= @bucket_threshold_size
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
      if @buckets_with_timers.add?(bucket_id)
        EM.add_timer(@bucket_max_age) do
          @on_bucket_timeout_callbacks.each do |callback|
            callback.call bucket_id
          end
        end
      end
    end

    def clear_timer(bucket_id)
      @buckets_with_timers.delete(bucket_id)
    end
  end
end
