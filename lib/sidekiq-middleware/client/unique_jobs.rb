module Sidekiq
  module Middleware
    module Client
      class UniqueJobs
        HASH_KEY_EXPIRATION = 30 * 60

        def call(worker_class, item, queue)
          worker_class = worker_class.constantize if worker_class.is_a?(String)

          enabled, expiration = worker_class.get_sidekiq_options['unique'],
            (worker_class.get_sidekiq_options['expiration'] || HASH_KEY_EXPIRATION)

          if enabled
            unique, payload = false, item.clone.slice(*%w(class queue args at))
            job_id = item['jid']

            # Enabled unique scheduled
            if enabled == :all && payload.has_key?('at')
              # Use expiration period as specified in configuration,
              # but relative to job schedule time
              expiration += (payload['at'].to_i - Time.now.to_i)
              payload.delete('at')
            end

            payload_hash = Sidekiq::Middleware::UniqueKey.generate(worker_class, payload)

            Sidekiq.redis do |conn|
              conn.watch(payload_hash)

              locked_job_id = conn.get(payload_hash)
              if locked_job_id && locked_job_id != job_id
                conn.unwatch
              else
                unique = conn.multi do
                  conn.setex(payload_hash, expiration, job_id)
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
