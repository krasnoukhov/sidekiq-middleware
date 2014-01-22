module Sidekiq
  module Middleware
    module Server
      class UniqueJobs
        def call(worker_instance, item, queue)
          worker_class = worker_instance.class
          enabled = worker_class.unique_enabled?(item)

          if enabled
            begin
              yield
            ensure
              unless worker_class.unique_manual?
                clear(worker_class, item)
              end
            end
          else
            yield
          end
        end

        def clear(worker_class, item)
          Sidekiq.redis do |conn|
            conn.del worker_class.unique_digest(item)
          end
        end
      end
    end
  end
end
