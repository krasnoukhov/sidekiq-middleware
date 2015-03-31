# encoding: utf-8

#
# The following classes extend their respective Sidekiq classes (in particular,
# they extend the delete/clear methods). The extensions make sure that the
# locks are removed from Redis when the jobs are.
#
# Reference:
# https://github.com/mperham/sidekiq/blob/master/lib/sidekiq/api.rb
# https://github.com/mperham/sidekiq/blob/master/lib/sidekiq/web.rb
#

module Sidekiq
  class Job
    module UniqueExtension
      def self.included(base)
        base.class_eval do
          alias_method :delete_orig, :delete
          alias_method :delete, :delete_ext
        end
      end

      def delete_ext
        cklass = klass.constantize
        cklass.unlock!(args.first) if cklass.respond_to? :lock
        delete_orig
      end
    end

    include UniqueExtension
  end

  class Queue
    module UniqueExtension
      def self.included(base)
        base.class_eval do
          alias_method :clear_orig, :clear
          alias_method :clear, :clear_ext
        end
      end

      def clear_ext
        self.each { |job| job.delete }
        clear_orig
      end
    end

    include UniqueExtension
  end

  class SortedSet
    module UniqueExtension
      def self.included(base)
        base.class_eval do
          alias_method :clear_orig, :clear
          alias_method :clear, :clear_ext
        end
      end

      def clear_ext
        self.each { |job| job.delete }
        clear_orig
      end
    end

    include UniqueExtension
  end
end
