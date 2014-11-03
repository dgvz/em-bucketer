require 'em-bucketer/ordered/database'
require 'em-hiredis'

module EventMachine::Bucketer
  module Ordered::Database
    module Redis
      private

      def setup_db
        redis.register_script(:lpopn, <<-END)
          local r = redis.call('lrange', KEYS[1], 0, ARGV[1] - 1)
          redis.call('ltrim', KEYS[1], ARGV[1], -1)
          return r
        END
        redis.register_script(:lpopa, <<-END)
          local r = redis.call('lrange', KEYS[1], 0, - 1)
          redis.call('del', KEYS[1])
          return r
        END
      end

      def bucket_size_from_db(bucket_id, &blk)
        EM::Completion.new.tap do |c|
          c.callback(&blk) if block_given?
          redis.llen(redis_key(bucket_id)).callback do |len|
            c.succeed len.to_i
          end.errback do |e|
            c.fail e
          end
        end
      end

      def add_item_to_db(bucket_id, item, &blk)
        EM::Completion.new.tap do |c|
          c.callback(&blk) if block_given?
          redis.rpush(redis_key(bucket_id), Marshal.dump(item)).callback do
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

      def pop_all_from_db(bucket_id, &blk)
        EM::Completion.new.tap do |c|
          c.callback(&blk) if block_given?
          redis.lpopa([redis_key(bucket_id)]).callback do |data|
            bucket = data.map { |d| Marshal.load(d) }
            c.succeed bucket
          end.errback do |e|
            c.fail e
          end
        end
      end

      def pop_count_from_db(bucket_id, count, &blk)
        EM::Completion.new.tap do |c|
          c.callback(&blk) if block_given?
          redis.lpopn([redis_key(bucket_id)], count).callback do |data|
            bucket = data.map { |d| Marshal.load(d) }
            c.succeed bucket
          end.errback do |e|
            c.fail e
          end
        end
      end

      def get_bucket_from_db(bucket_id, &blk)
        EM::Completion.new.tap do |c|
          c.callback(&blk) if block_given?
          redis.lrange(redis_key(bucket_id), 0, -1).callback do |data|
            bucket = data.map { |d| Marshal.load(d) }
            c.succeed bucket
          end.errback do |e|
            c.fail e
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
        "em_bucketer_ordered:#{redis_prefix}:#{bucket_id}"
      end

      def redis_known_buckets_key
        "em_bucketer_ordered_known_buckets:#{redis_prefix}"
      end
    end
  end
end
