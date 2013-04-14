is_test_env = (ENV["RAILS_ENV"] || ENV["RACK_ENV"]) == "test"

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
    chain.add Sidekiq::Middleware::Client::UniqueJobs unless is_test_env
  end
end
