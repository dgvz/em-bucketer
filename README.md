# Bucketizer

This is a generic tool for putting arbitrary objects into buckets and setting callbacks to be called when any bucket exceeds a specific threshold size. The interface is intentially written using blocks/callbacks as it is suited for use in EventMachine code.

Currently an in memory bucketizer is supported, however it is intended that a redis backed bucketizer will be added later and it will be using em-hiredis gem for redis interaction and it will actually be asynchronous.

## Installation

Add this line to your application's Gemfile:

    gem 'bucketizer'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install bucketizer

## Usage

```ruby
bucketizer = Bucketizer::InMemory.new(:bucket_threshold_size => 5)

bucketizer.on_bucket_full do |bucket_id|
  p "yay bucket #{bucket_id} filled up!"
end

bucketizer.add_item("1", "1", {:foo => :bar})
bucketizer.add_item("1", "2", {:foo => :bar})
bucketizer.add_item("1", "3", {:foo => :bar})
bucketizer.add_item("1", "4", {:bar => :foo})
bucketizer.add_item("1", "5", {:bar => :foo})
```

## Contributing

1. Fork it ( https://github.com/DylanGriffith/bucketizer/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
