Peeek
=====

Peeek peeks at calls of a method

Installation
------------

Add this line to your application's Gemfile:

    gem 'peeek'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install peeek

Usage
-----

You can peek at calls of a method by `Object#peeek` (or `Peeek#hook`).

    require 'peeek'

    String.peeek(:%) # or Peeek.current.hook(String, :%)

    format = '%s (%d)'
    puts format % ['Koyomi',  18]
    puts format % ['Karen',   14]
    puts format % ['Tsukihi', 14]

    puts Peeek.current.calls # => String#% from "%s (%d)" with ["Koyomi", 18] returned "Koyomi (18)" in peeek-example.rb at 6
                             # => String#% from "%s (%d)" with ["Karen", 14] returned "Karen (14)" in peeek-example.rb at 7
                             # => String#% from "%s (%d)" with ["Tsukihi", 14] returned "Tsukihi (14)" in peeek-example.rb at 8

### How to hook to a method

Call `Object#peeek` to any module or any class, hook to their instance methods.

    String.peeek(:%)

Also for an instance of any class, hook to its singleton methods.

    $stdout.peeek(:write)

If want to choose whether to hook to either instance method or singleton method,
add "#" before in the method name in instance method, add "." in singleton
method.

    String.peeek('#%')
    $stdout.peeek('.write')
    Kernel.peeek('.puts')

Even if the method isn't defined at the time you call `Object#peeek`, enable the
hook when the method is defined.

    Kernel.peeek('.pp')
    require 'pp' # enable the hook
    pp {'Koyomi' => 18, 'Karen' => 14, 'Tsukihi' => 14}

### Localize a Peeek object

`Peeek.local` enables hooks only in a block.

    require 'peeek'

    format = '%s (%d)'

    calls = Peeek.local do
      String.peeek(:%)
      puts format % ['Koyomi', 18]
      Peeek.current.calls
    end

    puts calls # => String#% from "%s (%d)" with ["Koyomi", 18] returned "Koyomi (18)" in peeek-local.rb at 7

    puts format % ['Karen', 14] # not captured

Hook to methods at head of the block, and return the calls, then use
`Peeek.capture`.

    require 'peeek'

    format = '%s (%d)'

    calls = Peeek.capture(String => :%) do
      puts format % ['Koyomi',  18]
    end

    puts calls # => String#% from "%s (%d)" with ["Koyomi", 18] returned "Koyomi (18)" in peeek-capture.rb at 6

    puts format % ['Karen', 14] # not captured

### Filter calls

`Peeek#calls` or `Peeek.local` return an instance of `Peeek::Calls`. It has
implemented methods to filter by attributes of the call.

    require 'peeek'

    format = '%s (%d)'

    calls = Peeek.capture(String => :%) do
      puts format % ['Koyomi', 18]
      puts format % ['Karen'] rescue $!
    end

    puts calls.in('peeek-calls.rb') # filter by file name
    puts calls.in(/\.rb/)           # can also use regular expressions
    puts calls.at(6)                # filter by line number
    puts calls.at(1..10)            # can also use range
    puts calls.from('%s (%d)')      # filter by receiver
    puts calls.return_values        # filter only calls that returned a value
    puts calls.exceptions           # filter only calls that raised an exception


Contributing
------------

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
