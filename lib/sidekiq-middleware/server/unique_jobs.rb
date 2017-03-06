module Sidekiq
  module Middleware
    module Server
      class UniqueJobs
        def call(worker_instance, item, queue)
          worker_class = worker_instance.class
          enabled = Sidekiq::Middleware::Helpers.unique_enabled?(worker_class, item)

          if enabled
            begin
              yield
              successful = true
            ensure
              unless Sidekiq::Middleware::Helpers.unique_manual?(worker_class)
                unlock_after_failure = Sidekiq::Middleware::Helpers.unlock_after_failure?(worker_class)
                clear(worker_class, item) if unlock_after_failure || successful || dead?(item)
              end
            end
          else
            yield
          end
        end

        def clear(worker_class, item)
          Sidekiq.redis do |conn|
            conn.del Sidekiq::Middleware::Helpers.unique_digest(worker_class, item)
          end
        end

        private

        def dead?(item)
          item['retry'] == (item['retry_count'].to_i + 1)
        end
      end
    end
  end
end
