module Sidekiq
  module Middleware
    module Server
      class UniqueJobs

        def call(worker_instance, item, queue)
          forever = worker_instance.class.get_sidekiq_options['forever']

          # Delete lock first if forever is set
          # Used for jobs which may scheduling self in future
          if forever == :manual
            worker_instance.instance_variable_set(:@unique_lock_key, unique_lock_key(worker_instance, item, queue))
          elsif forever
            clear(worker_instance, item, queue) if forever
          end

          begin
            yield
          ensure
            clear(worker_instance, item, queue) unless forever
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
