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
            ensure
              unless Sidekiq::Middleware::Helpers.unique_manual?(worker_class)
                clear(worker_class, item)
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
      end
    end
  end
end
