module Sidekiq
  module Middleware
    module UniqueKey
      def self.generate(worker_class, payload)
        if worker_class.respond_to?(:lock)
          worker_class.lock(*payload['args'])
        else
          json = Sidekiq.dump_json(payload)
          "locks:unique:#{Digest::MD5.hexdigest(json)}"
        end
      end
    end
  end
end
