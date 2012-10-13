require 'securerandom'
require 'helper'
require 'sidekiq/client'
require 'sidekiq/worker'
require 'sidekiq/processor'
require 'sidekiq-middleware'

class TestUniqueJobs < MiniTest::Unit::TestCase
  describe 'with real redis' do
    before do
      @boss = MiniTest::Mock.new
      @processor = ::Sidekiq::Processor.new(@boss)
      
      Sidekiq.redis = REDIS
      Sidekiq.redis {|c| c.flushdb }
    end

    class UniqueWorker
      include Sidekiq::Worker
      sidekiq_options queue: :unique_queue, unique: true

      def perform(x)
      end
    end

    it 'does not duplicate messages with enabled unique option' do
      5.times { UniqueWorker.perform_async('args') }
      assert_equal 1, Sidekiq.redis { |c| c.llen('queue:unique_queue') }
    end

    it 'discards non critical information about the message' do
      5.times { Sidekiq::Client.push('class' => UniqueWorker, 'args' => ['critical'], 'sent_at' => Time.now.to_f, 'non' => 'critical') }
      assert_equal 1, Sidekiq.redis { |c| c.llen('queue:unique_queue') }
    end

    class NotUniqueWorker
      include Sidekiq::Worker
      sidekiq_options queue: :not_unique_queue, unique: false

      def perform(x)
      end
    end

    it 'duplicates messages with disabled unique option' do
      5.times { NotUniqueWorker.perform_async('args') }
      assert_equal 5, Sidekiq.redis { |c| c.llen('queue:not_unique_queue') }
    end

    class UniqueScheduledWorker
      include Sidekiq::Worker
      sidekiq_options queue: :unique_scheduled_queue, unique: :all, forever: true

      def perform(x)
        UniqueScheduledWorker.perform_in(60, x)
      end
    end

    it 'does not duplicate scheduled messages with enabled unique option' do
      5.times { |t| UniqueScheduledWorker.perform_in((t+1)*60, 'args') }
      assert_equal 1, Sidekiq.redis { |c| c.zcard('schedule') }
    end

    it 'allows the job to reschedule itself with enabled forever option' do
      5.times {
        msg = Sidekiq.dump_json('class' => UniqueScheduledWorker.to_s, 'args' => ['something'])
        @boss.expect(:processor_done!, nil, [@processor])
        @processor.process(msg, 'default')
        @boss.verify
      }
      assert_equal 1, Sidekiq.redis { |c| c.zcard('schedule') }
    end

    it 'discards non critical information about the message' do
      5.times {|i|
        msg = Sidekiq.dump_json('class' => UniqueScheduledWorker.to_s, 'args' => ['something'], 'sent_at' => (Time.now + i*60).to_f)
        @boss.expect(:processor_done!, nil, [@processor])
        @processor.process(msg, 'default')
        @boss.verify
      }
      assert_equal 1, Sidekiq.redis { |c| c.zcard('schedule') }
    end
  end
end
