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
              # Give scheduled job a hour to perform
              expiration = (payload['at'].to_i - Time.now.to_i + 60 * 60)
              payload.delete('at')
            end

            payload_hash = "locks:unique:#{Digest::MD5.hexdigest(Sidekiq.dump_json(payload))}"

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
