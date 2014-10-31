require 'eventmachine'

module EventMachine::Bucketer
  # This is a purpose built class for storing arbitrary
  # objects in buckets then calling callbacks when any
  # of those buckets exceed a certain pre-specified
  # size. The interface is intentially evented looking
  # so that it would be possible to later swap out the
  # backing database with a more persistent database
  # (eg. redis). If this interface was using regular
  # returns this would mean clients would need to change
  # later if we decided to use redis.
  class InMemory
    BUCKET_THRESHOLD_SIZE_DEFAULT = 1000
    BUCKET_MAX_AGE_DEFAULT = 3600

    # Creates a new in memory Bucketer with the requested
    # configurations
    #
    # @param bucket_threshold_size [Integer] the max size of the bucket
    # after which the on_bucket_full callback is called
    # @param bucket_max_age [Integer] max number of seconds a bucket
    # can remain before the on_bucket_timed_out is called
    def initialize(bucket_threshold_size: BUCKET_THRESHOLD_SIZE_DEFAULT, bucket_max_age: BUCKET_MAX_AGE_DEFAULT)
      @bucket_threshold_size = bucket_threshold_size
      @bucket_max_age = bucket_max_age
      @buckets = {}
      @on_bucket_full_callbacks = []
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
      EM::Completion.new.tap do |c|
        c.callback(&blk) if block_given?
        add_bucket_to_db(bucket_id, item_id, item) { c.succeed }
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

    # Get the contents of a bucket.
    #
    # @param bucket_id [String] the bucket id
    # of the bucket you want to get
    # @yield [Array] the items you put
    # into the bucket
    def get_bucket(bucket_id, &blk)
      EM::Completion.new.tap do |c|
        c.callback(&blk) if block_given?
        get_bucket_from_db(bucket_id) do |bucket|
          c.succeed bucket.values
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
        get_bucket(bucket_id) do |contents|
          empty_bucket(bucket_id) do
            c.succeed contents
          end
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
        empty_bucket_in_db(bucket_id) do
          c.succeed
        end
      end
    end

    private

    def bucket_full?(bucket_id, &blk)
      bucket_size_from_db(bucket_id) do |size|
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

    #### BEGIN DATABASE METHODS ####
    def bucket_size_from_db(bucket_id, &blk)
      @buckets[bucket_id] ||= {}
      blk.call @buckets[bucket_id].size
    end

    def add_bucket_to_db(bucket_id, item_id, item, &blk)
      @buckets[bucket_id] ||= {}
      @buckets[bucket_id][item_id] = item
      blk.call if block_given?
    end

    def get_bucket_from_db(bucket_id, &blk)
      @buckets[bucket_id] ||= {}
      blk.call @buckets[bucket_id]
    end

    def empty_bucket_in_db(bucket_id, &blk)
      @buckets[bucket_id] = {}
      blk.call
    end
    #### END DATABASE METHODS ####
  end
end
