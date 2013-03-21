# Peeek

TODO: Write a gem description

## Installation

Add this line to your application's Gemfile:

    gem 'peeek'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install peeek

## Usage

    require 'peeek'

    peeek = Peeek.new

    peeek.hook(String, :to_s) do |call|
      p call.receiver
    end

    '1'.to_s # => "1"
    '2'.to_s # => "2"

    puts peeek.calls # => #<Peeek::Hook String#to_s (linked)> from "1" in peeek-example.rb at 9
                     # => #<Peeek::Hook String#to_s (linked)> from "2" in peeek-example.rb at 10

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
