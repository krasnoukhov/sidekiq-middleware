module Sidekiq
  module Middleware
    module Server
      class UniqueJobs

        def call(worker_instance, item, queue)
          manual = worker_instance.class.get_sidekiq_options['manual']

          begin
            yield
          ensure
            clear(worker_instance, item, queue) unless manual
          end
        end

        def unique_lock_key(worker_instance, item, queue)
          # Only enforce uniqueness across class, queue, args, and at.
          # Useful when middleware uses the payload to store metadata.
          enabled, payload = worker_instance.class.get_sidekiq_options['unique'],
            item.clone.slice(*%w(class queue args at))

          # Enabled unique scheduled
          if enabled == :all && payload.has_key?('at')
            payload.delete('at')
          end

          Sidekiq::Middleware::UniqueKey.generate(worker_instance.class, payload)
        end

        def clear(worker_instance, item, queue)
          Sidekiq.redis { |conn| conn.del unique_lock_key(worker_instance, item, queue) }
        end
      end
    end
  end
end
