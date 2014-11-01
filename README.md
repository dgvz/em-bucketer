# EventMachine::Bucketer

This is a generic EventMachine library for putting arbitrary objects into
buckets and setting callbacks to be called when any bucket exceeds a specific
threshold size. Although the `Bucketer::InMemory` is synchronous (it's just
using a ruby hash) the interface is still what would be expected for an
asynchronous API for consistency with other Bucketers that are actually
asynchronous.

## Installation

Add this line to your application's Gemfile:

    gem 'em-bucketer'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install em-bucketer

## Usage

```ruby
require 'em-bucketer'
EM.run do
  bucketer = EM::Bucketer::InMemory.new(:bucket_threshold_size => 5)

  bucketer.on_bucket_full do |bucket_id|
    p "yay bucket #{bucket_id} filled up!"

    bucketer.get_and_empty_bucket(bucket_id) do |items|
      EM.stop
      items.each do |item|
        p "got back #{item}"
      end
    end
  end

  bucketer.add_item("1", "1", {:foo => :bar})
  bucketer.add_item("1", "2", {:foo => :bar})
  bucketer.add_item("1", "3", {:foo => :bar})
  bucketer.add_item("1", "4", {:bar => :foo})
  bucketer.add_item("1", "5", {:bar => :foo})
end
```

## Redis Bucketer

This gem also supports a redis backed bucketer which uses the `em-hiredis` gem.
This bucketer uses `Marshal.dump` to store objects in redis and thus there are
limitations on what can be placed in a bucket. Specifically you cannot store
procs in buckets using the redis bucketer.

## Contributing

1. Fork it ( https://github.com/dgvz/em-bucketer/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
