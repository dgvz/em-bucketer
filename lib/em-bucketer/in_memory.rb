require 'eventmachine'
require 'em-bucketer/database/hash'
require 'em-bucketer/base'

module EventMachine::Bucketer
  class InMemory
    include Database::Hash
    include Base

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
      setup(bucket_threshold_size, bucket_max_age)
    end
  end
end
