module Sidekiq
  module Middleware
    module Client
      class UniqueJobs
        HASH_KEY_EXPIRATION = 30 * 60

        def call(worker_class, item, queue)
          enabled, expiration = worker_class.get_sidekiq_options['unique'],
            (worker_class.get_sidekiq_options['expiration'] || HASH_KEY_EXPIRATION)

          if enabled
            unique, payload = false, item.clone.slice(*%w(class queue args at))

            # Enabled unique scheduled
            if enabled == :all && payload.has_key?('at')
              scheduled_expiration = (payload['at'].to_i - Time.now.to_i)
              expiration = scheduled_expiration if scheduled_expiration > expiration
              payload.delete('at')
            end

            payload_hash = Sidekiq::Middleware::UniqueKey.generate(worker_class, payload)

            Sidekiq.redis do |conn|
              conn.watch(payload_hash)

              if conn.get(payload_hash)
                conn.unwatch
              else
                unique = conn.multi do
                  conn.setex(payload_hash, expiration, 1)
                end
              end
            end

            yield if unique
          else
            yield
          end
        end
      end
    end
  end
end
