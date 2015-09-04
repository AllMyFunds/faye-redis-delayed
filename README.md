# Faye::RedisDelayed [![Gem Version](https://badge.fury.io/rb/faye-redis-delayed.png)](http://badge.fury.io/rb/faye-redis-delayed) [![Circle CI](https://circleci.com/gh/monterail/faye-redis-delayed.png?style=shield)](https://circleci.com/gh/monterail/faye-redis-delayed)

> Delayed Redis engine back-end for [Faye](http://faye.jcoglan.com/) Ruby server. Enables delivey of messages that were sent *before* a client has connected to the channel.

Turn this timeline:

![Regular faye](https://monterail-share.s3.amazonaws.com/public/codetunes/2013-02-11-robust-dashboard-application-with-faye/tymon-faye-timeline1.png)

…into that:

![RedisDelayed faye](https://monterail-share.s3.amazonaws.com/public/codetunes/2013-02-11-robust-dashboard-application-with-faye/tymon-faye-timeline2.png)

You can read about the [real case scenario](http://codetunes.com/2013/robust-dashboard-application-with-faye/) for the engine.

## Installation

Add this line to your application’s `Gemfile`:

```rb
gem 'faye-redis-delayed'
```

## Usage

When initializing a new Faye server, reference the engine and pass any required settings.

```rb
# faye config.ru
require 'faye'
require 'faye/redis_delayed'

server = Faye::RackAdapter.new(
  :mount   => '/',
  :timeout => 25,
  :engine  => {
    :type   => Faye::RedisDelayed,  # set the engine type
    :expire => 30                   # undelivered messages will expire in 30 seconds
    # …                             # other Faye::Redis engine options
  }
)

run server
```

Additional options provided by `Faye::DelayedRedis`:

* `:expire` — expire time in seconds, defaults to `60`
* `:delay_channels` - Array of channels that should be delayed
* `:offline_channels` - Array of channels that should fire the `offline_callback` if no clients connected to them
* `:offline_callback` - Callback responding to `#call(message)` method where message matches `offline_channels`

`:delay_channels` and `:offline_channels` can be specified as strings or as regular expressions.
If something is given, then only channels matching one of the listed
patterns will be delayed.  Without this argument, every channel is
delayed.

```rb
  :engine  => {
    :type           => Faye::RedisDelayed,
    :delay_channels => [/^\/queues_with_this_prefix/, "/this/one/queue"],
  }
```

See the full list of [`Faye::Redis` engine options](https://github.com/faye/faye-redis-ruby).

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
