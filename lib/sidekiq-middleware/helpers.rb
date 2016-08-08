module Sidekiq
  module Middleware
    module Helpers
      extend self

      UNIQUE_EXPIRATION = 30 * 60 # 30 minutes

      def unique_digest(klass, item)
        # regular sidekiq job enabled class
        if klass.respond_to?(:lock)
          args = item['args']
          klass.lock(*args)
        # wrapped ActiveJob sidekiq job
        elsif active_job?(klass)
          active_job_unique_digest(klass, item)
        else
          default_unique_digest(item)
        end
      end

      def active_job?(klass)
        defined?(ActiveJob::QueueAdapters::SidekiqAdapter::JobWrapper) &&
          ActiveJob::QueueAdapters::SidekiqAdapter::JobWrapper == klass
      end

      def active_job_unique_digest(klass, item)
        job_class = item["wrapped"] # original job class
        job_class = job_class.constantize

        queue = item["queue"]
        arguments = item["args"].first["arguments"].join(':')

        if klass.get_sidekiq_options['human_readable']
          encoded = arguments unless arguments.blank?
        else
          dumped = Sidekiq.dump_json([queue, arguments])
          encoded = Digest::MD5.hexdigest(dumped)
        end

        ["locks:unique:#{job_class}", encoded].compact.join(':')
      end

      def default_unique_digest(item)
        dumped = Sidekiq.dump_json(item.slice('class', 'queue', 'args'))
        digest = Digest::MD5.hexdigest(dumped)
        "locks:unique:#{item['class']}:#{digest}"
      end

      def unique_expiration(klass)
        klass.get_sidekiq_options['expiration'] || UNIQUE_EXPIRATION
      end

      def unique_enabled?(klass, item)
        enabled = klass.get_sidekiq_options['unique']
        if item.has_key?('at') && enabled != :all
          enabled = false
        end
        enabled
      end

      def unique_manual?(klass)
        klass.get_sidekiq_options['manual']
      end
    end
  end
end
