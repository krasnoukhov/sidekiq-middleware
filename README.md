# Additional sidekiq middleware

This gem provides additional middleware for [Sidekiq](github.com/mperham/sidekiq/).

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

Put this code in initialize section:

```ruby
  Sidekiq.configure_server do |config|
    config.server_middleware do |chain|
     chain.add Sidekiq::Middleware::Server::UniqueJobs
    end
    config.client_middleware do |chain|
     chain.add Sidekiq::Middleware::Client::UniqueJobs
    end
  end
  
  Sidekiq.configure_client do |config|
    config.client_middleware do |chain|
      chain.add Sidekiq::Middleware::Client::UniqueJobs
    end
  end
```

Example worker:

```ruby
  class UniqueWorker
    include Sidekiq::Worker
  
    sidekiq_options({
      # Should be set to true (enables uniqueness for async jobs)
      # or :all (enables uniqueness for both async and scheduled jobs)
      unique: :all,
  
      # Set this to true in case your job schedules itself
      forever: true,
  
      # Unique expiration (optional, default is 30 minutes)
      expiration: 24 * 60 * 60
    })
  
    def perform
      # Your code goes here
    end
  end
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
