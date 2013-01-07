module Sidekiq
  module Middleware
    module Server
      class UniqueJobs

        def call(worker_instance, item, queue)
          forever = worker_instance.class.get_sidekiq_options['forever']

          # Delete lock first if forever is set
          # Used for jobs which may scheduling self in future
          clear(worker_instance, item, queue) if forever

          begin
            yield
          ensure
            clear(worker_instance, item, queue) unless forever
          end
        end

        def clear(worker_instance, item, queue)
          # Only enforce uniqueness across class, queue, args, and at.
          # Useful when middleware uses the payload to store metadata.
          enabled, payload = worker_instance.class.get_sidekiq_options['unique'],
            item.clone.slice(*%w(class queue args at))

          # Enabled unique scheduled 
          if enabled == :all && payload.has_key?('at')
            payload.delete('at')
          end

          Sidekiq.redis { |conn| conn.del "locks:unique:#{Digest::MD5.hexdigest(Sidekiq.dump_json(payload))}" }
        end
      end
    end
  end
end
