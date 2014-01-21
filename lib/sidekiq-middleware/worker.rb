module Sidekiq
  module Middleware
    module Worker
      UNIQUE_EXPIRATION = 30 * 60 # 30 minutes

      def unique_digest(item)
        if respond_to?(:lock)
          args = item['args']
          lock(*args)
        else
          dumped = Sidekiq.dump_json(item.slice('class', 'queue', 'args'))
          digest = Digest::MD5.hexdigest(dumped)

          "locks:unique:#{digest}"
        end
      end

      def unique_exiration
        get_sidekiq_options['expiration'] || UNIQUE_EXPIRATION
      end

      def unique_enabled?(item)
        enabled = get_sidekiq_options['unique']
        if item.has_key?('at') && enabled != :all
          enabled = false
        end
        enabled
      end

      def unique_manual?
        get_sidekiq_options['manual']
      end
    end
  end
end

Sidekiq::Worker::ClassMethods.class_eval do
  include Sidekiq::Middleware::Worker
end
