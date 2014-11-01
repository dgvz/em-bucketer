require 'em-bucketer/database'
require 'em-hiredis'

module EventMachine::Bucketer
  module Database
    module Redis
      private

      def bucket_size_from_db(bucket_id, &blk)
        EM::Completion.new.tap do |c|
          c.callback(&blk) if block_given?
          redis.hlen(redis_key(bucket_id)).callback do |len|
            c.succeed len.to_i
          end.errback do |e|
            c.fail e
          end
        end
      end

      def add_bucket_to_db(bucket_id, item_id, item, &blk)
        EM::Completion.new.tap do |c|
          c.callback(&blk) if block_given?
          redis.hset(redis_key(bucket_id), item_id, Marshal.dump(item)).callback do
            add_to_known_buckets(bucket_id).callback do
              c.succeed
            end.errback do |e|
              c.fail e
            end
          end.errback do |e|
            c.fail e
          end
        end
      end

      def get_bucket_from_db(bucket_id, &blk)
        EM::Completion.new.tap do |c|
          c.callback(&blk) if block_given?
          redis.hgetall(redis_key(bucket_id)) do |data|
            bucket = {}
            index = 0
            while(index < data.size)
              bucket[data[index]] = Marshal.load(data[index + 1])
              index += 2
            end
            c.succeed bucket
          end.errback do |e|
            c.errback
          end
        end
      end

      def empty_bucket_in_db(bucket_id, &blk)
        EM::Completion.new.tap do |c|
          c.callback(&blk) if block_given?
          redis.del(redis_key(bucket_id)).callback do
            remove_from_known_buckets(bucket_id).callback do
              c.succeed
            end.errback do |e|
              c.fail e
            end
          end.errback do |e|
            c.fail e
          end
        end
      end

      def known_buckets(&blk)
        redis.smembers(redis_known_buckets_key, &blk)
      end

      def add_to_known_buckets(bucket_id, &blk)
        redis.sadd(redis_known_buckets_key, bucket_id, &blk)
      end

      def remove_from_known_buckets(bucket_id, &blk)
        redis.srem(redis_known_buckets_key, bucket_id, &blk)
      end

      def redis_key(bucket_id)
        "em_bucketer:#{redis_prefix}:#{bucket_id}"
      end

      def redis_known_buckets_key
        "em_bucketer_known_buckets:#{redis_prefix}"
      end
    end
  end
end
