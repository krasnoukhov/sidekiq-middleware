source 'https://rubygems.org'
gemspec

gem 'sidekiq', ENV['SIDEKIQ_VERSION'] if ENV['SIDEKIQ_VERSION']

group :test do
  gem 'simplecov', require: false
  gem 'coveralls', require: false
end
