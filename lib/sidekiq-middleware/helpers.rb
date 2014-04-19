module Sidekiq
  module Middleware
    module Helpers
      extend self

      UNIQUE_EXPIRATION = 30 * 60 # 30 minutes

      def unique_digest(klass, item)
        if klass.respond_to?(:lock)
          args = item['args']
          klass.lock(*args)
        else
          dumped = Sidekiq.dump_json(item.slice('class', 'queue', 'args'))
          digest = Digest::MD5.hexdigest(dumped)

          "locks:unique:#{digest}"
        end
      end

      def unique_exiration(klass)
        klass.get_sidekiq_options['expiration'] || UNIQUE_EXPIRATION
      end

      def unique_enabled?(klass, item)
        enabled = klass.get_sidekiq_options['unique']
        if item.has_key?('at') && enabled != :all
          enabled = false
        end
        enabled
      end

      def unlock_after_failure?(klass)
        !klass.get_sidekiq_options['lock_after_failure']
      end

      def unique_manual?(klass)
        klass.get_sidekiq_options['manual']
      end
    end
  end
end
