require 'em-bucketer/ordered/database'

module EventMachine::Bucketer
  module Ordered
    module Database
      module Hash
        private

        def pop_all_from_db(bucket_id, &blk)
          EM::Completion.new.tap do |c|
            c.callback(&blk) if block_given?
            all = bucket_by_id(bucket_id)
            @buckets[bucket_id] = []
            c.succeed all
          end
        end

        def pop_count_from_db(bucket_id, count, &blk)
          EM::Completion.new.tap do |c|
            c.callback(&blk) if block_given?
            all = bucket_by_id(bucket_id)
            result = all.first(count)
            @buckets[bucket_id] = all[count..-1]
            c.succeed result
          end
        end

        def bucket_size_from_db(bucket_id, &blk)
          EM::Completion.new.tap do |c|
            c.callback(&blk) if block_given?
            c.succeed bucket_by_id(bucket_id).count
          end
        end

        def add_item_to_db(bucket_id, item, &blk)
          EM::Completion.new.tap do |c|
            c.callback(&blk) if block_given?
            bucket_by_id(bucket_id) << item
            c.succeed
          end
        end

        def get_bucket_from_db(bucket_id, &blk)
          EM::Completion.new.tap do |c|
            c.callback(&blk) if block_given?
            c.succeed bucket_by_id(bucket_id)
          end
        end

        def empty_bucket_in_db(bucket_id, &blk)
          EM::Completion.new.tap do |c|
            c.callback(&blk) if block_given?
            @buckets[bucket_id] = []
            c.succeed
          end
        end

        def bucket_by_id(bucket_id)
          @buckets[bucket_id] ||= []
        end
      end
    end
  end
end
