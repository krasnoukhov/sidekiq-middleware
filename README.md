# Additional sidekiq middleware

This gem provides additional middleware for [Sidekiq](github.com/mperham/sidekiq/).

Now it contains the following middlewares:

* UniqueJobs (both client and server)

## Installation

Add this line to your application's Gemfile:

    gem 'sidekiq-middleware'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sidekiq-middleware

## Usage

For example (put this code in initialize section):

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

See [Sidekiq Wiki](https://github.com/mperham/sidekiq/wiki/Middleware) for more details.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
