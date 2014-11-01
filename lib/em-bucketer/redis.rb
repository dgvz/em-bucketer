require 'eventmachine'
require 'em-bucketer/database/redis'
require 'em-bucketer/base'

module EventMachine::Bucketer
  class Redis
    include Database::Redis
    include Base

    BUCKET_THRESHOLD_SIZE_DEFAULT = 1000
    BUCKET_MAX_AGE_DEFAULT = 3600

    # Creates a new redis Bucketer with the requested
    # configurations.
    # *NOTE* The redis bucketer uses Marshal to store
    # the objects in redis. This puts limitations on
    # the data that cannot be stored in these buckets.
    # For example you cannot store an object that
    # references a proc as an instance variable.
    #
    # @param redis_prefix [String] The prefix for the
    # bucket in redis. This is necessary because you
    # may want to have multiple bucketers using one
    # redis instance and you don't want them conflicting.
    # Also this can't just be random because the whole
    # point of the redis bucketer is that you can restart
    # your app and get back the same bucketer without any
    # data loss.
    # @param bucket_threshold_size [Integer] the max size of the bucket
    # after which the on_bucket_full callback is called
    # @param bucket_max_age [Integer] max number of seconds a bucket
    # can remain before the on_bucket_timed_out is called
    def initialize(redis_prefix, bucket_threshold_size: BUCKET_THRESHOLD_SIZE_DEFAULT, bucket_max_age: BUCKET_MAX_AGE_DEFAULT)
      @redis = EM::Hiredis.connect
      @redis_prefix = redis_prefix
      setup(bucket_threshold_size, bucket_max_age)
    end

    # Used by Database::Redis
    attr_reader :redis_prefix, :redis
  end
end
