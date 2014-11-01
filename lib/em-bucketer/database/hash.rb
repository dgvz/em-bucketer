require 'em-bucketer/database'

module EventMachine::Bucketer
  module Database
    module Hash
      private

      def bucket_size_from_db(bucket_id, &blk)
        EM::Completion.new.tap do |c|
          c.callback(&blk) if block_given?
          @buckets[bucket_id] ||= {}
          c.succeed @buckets[bucket_id].size
        end
      end

      def add_bucket_to_db(bucket_id, item_id, item, &blk)
        EM::Completion.new.tap do |c|
          c.callback(&blk) if block_given?
          @buckets[bucket_id] ||= {}
          @buckets[bucket_id][item_id] = item
          c.succeed
        end
      end

      def get_bucket_from_db(bucket_id, &blk)
        EM::Completion.new.tap do |c|
          c.callback(&blk) if block_given?
          @buckets[bucket_id] ||= {}
          c.succeed @buckets[bucket_id]
        end
      end

      def empty_bucket_in_db(bucket_id, &blk)
        EM::Completion.new.tap do |c|
          c.callback(&blk) if block_given?
          @buckets[bucket_id] = {}
          c.succeed
        end
      end
    end
  end
end
