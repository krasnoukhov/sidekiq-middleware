# Additional sidekiq middleware

[![Gem Version](https://badge.fury.io/rb/sidekiq-middleware.png)](http://badge.fury.io/rb/sidekiq-middleware)
[![Dependency Status](https://gemnasium.com/krasnoukhov/sidekiq-middleware.png)](https://gemnasium.com/krasnoukhov/sidekiq-middleware)
[![Code Climate](https://codeclimate.com/github/krasnoukhov/sidekiq-middleware.png)](https://codeclimate.com/github/krasnoukhov/sidekiq-middleware)
[![Build Status](https://secure.travis-ci.org/krasnoukhov/sidekiq-middleware.png)](http://travis-ci.org/krasnoukhov/sidekiq-middleware)
[![Coverage Status](https://coveralls.io/repos/krasnoukhov/sidekiq-middleware/badge.png)](https://coveralls.io/r/krasnoukhov/sidekiq-middleware)


This gem provides additional middleware for [Sidekiq](https://github.com/mperham/sidekiq).

See [Sidekiq Wiki](https://github.com/mperham/sidekiq/wiki/Middleware) for more details.

## Installation

Add this line to your application's Gemfile:

    gem 'sidekiq-middleware'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sidekiq-middleware

## Contents

### UniqueJobs

Provides uniqueness for jobs.

**Usage**

Example worker:

```ruby
class UniqueWorker
  include Sidekiq::Worker

  sidekiq_options({
    # Should be set to true (enables uniqueness for async jobs)
    # or :all (enables uniqueness for both async and scheduled jobs)
    unique: :all,

    # Unique expiration (optional, default is 30 minutes)
    # For scheduled jobs calculates automatically based on schedule time and expiration period
    expiration: 24 * 60 * 60
  })

  def perform
    # Your code goes here
  end
end
```

Custom lock key and manual expiration:

```ruby
class UniqueWorker
  include Sidekiq::Worker

  sidekiq_options({
    unique: :all,
    expiration: 24 * 60 * 60,
    
    # Set this to true when you need to handle locks manually.
    # You'll be able to handle unique expiration inside your worker.
    # Please see example below.
    manual: true
  })
  
  # Implement your own lock string
  def self.lock(id)
    "locks:unique:#{id}"
  end
  
  # Implement method to handle lock removing manually
  def self.unlock!(id)
  	lock = self.lock(id)
    Sidekiq.redis { |conn| conn.del(lock) }
  end

  def perform(id)
    # Your code goes here
    # You are able to re-schedule job from perform method,
    # Just remove lock manually before performing job again.
    sleep 5
    
    # Re-schedule!
    self.class.unlock!(id)
    self.class.perform_async(id)
  end
end
```


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
