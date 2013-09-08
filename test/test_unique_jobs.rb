require 'securerandom'
require 'helper'
require 'timecop'
require 'sidekiq/client'
require 'sidekiq/worker'
require 'sidekiq/processor'
require 'sidekiq-middleware'

class TestUniqueJobs < MiniTest::Unit::TestCase
  describe 'with real redis' do
    before do
      Celluloid.boot
      @boss = MiniTest::Mock.new
      @processor = ::Sidekiq::Processor.new(@boss)

      Sidekiq.redis = REDIS
      Sidekiq.redis {|c| c.flushdb }
    end

    UnitOfWork = Struct.new(:queue, :message) do
      def acknowledge
        # nothing to do
      end

      def queue_name
        queue
      end

      def requeue
        # nothing to do
      end
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
      sidekiq_options queue: :unique_scheduled_queue, unique: :all

      def perform(x)
      end
    end

    it 'does not duplicate scheduled messages with enabled unique option' do
      5.times { |t| UniqueScheduledWorker.perform_in((t+1)*60, 'args') }
      assert_equal 1, Sidekiq.redis { |c| c.zcard('schedule') }
    end

    it 'does correctly handle adding to the worker queue when scheduled' do
      start_time = Time.now - 60
      queue_time = start_time + 30
      Timecop.travel start_time do
        UniqueScheduledWorker.perform_at queue_time, 'x'
      end
      assert_equal 1, Sidekiq.redis { |c| c.zcard('schedule') }
      assert_equal 0, Sidekiq.redis { |c| c.llen('queue:unique_scheduled_queue') }
      Sidekiq::Scheduled::Poller.new.poll
      assert_equal 0, Sidekiq.redis { |c| c.zcard('schedule') }
      assert_equal 1, Sidekiq.redis { |c| c.llen('queue:unique_scheduled_queue') }
    end

    it 'allows the job to be re-scheduled after processing' do
      # Schedule
      5.times { |t| UniqueScheduledWorker.perform_in((t+1)*60, 'args') }
      assert_equal 1, Sidekiq.redis { |c| c.zcard('schedule') }

      # Process
      msg = Sidekiq.dump_json('class' => UniqueScheduledWorker.to_s, 'queue' => 'unique_scheduled_queue', 'args' => ['args'])
      actor = MiniTest::Mock.new
      actor.expect(:processor_done, nil, [@processor])
      actor.expect(:real_thread, nil, [nil, Celluloid::Thread])
      2.times { @boss.expect(:async, actor, []) }
      work = UnitOfWork.new('default', msg)
      @processor.process(work)

      # Re-schedule
      5.times { |t| UniqueScheduledWorker.perform_in((t+1)*60, 'args') }
      assert_equal 2, Sidekiq.redis { |c| c.zcard('schedule') }
    end

    class CustomUniqueWorker
      include Sidekiq::Worker
      sidekiq_options queue: :custom_unique_queue, unique: :all, manual: true

      def self.lock(id, unlock)
        "custom:unique:lock:#{id}"
      end

      def self.unlock!(id, unlock)
        lock = self.lock(id, unlock)
        Sidekiq.redis { |conn| conn.del(lock) }
      end

      def perform(id, unlock)
        self.class.unlock!(id, unlock) if unlock
        CustomUniqueWorker.perform_in(60, id, unlock)
      end
    end

    it 'does not duplicate messages with enabled unique option and custom unique lock key' do
      5.times { CustomUniqueWorker.perform_async('args', false) }
      assert_equal 1, Sidekiq.redis { |c| c.llen('queue:custom_unique_queue') }
      job = Sidekiq.load_json Sidekiq.redis { |c| c.lpop('queue:custom_unique_queue') }
      assert job['jid']
      assert_equal job['jid'], Sidekiq.redis { |c| c.get('custom:unique:lock:args') }
    end

    it 'does not allow the job to be duplicated when processing job with manual option' do
      5.times {
        msg = Sidekiq.dump_json('class' => CustomUniqueWorker.to_s, 'args' => ['something', false])
        actor = MiniTest::Mock.new
        actor.expect(:processor_done, nil, [@processor])
        actor.expect(:real_thread, nil, [nil, Celluloid::Thread])
        2.times { @boss.expect(:async, actor, []) }
        work = UnitOfWork.new('default', msg)
        @processor.process(work)
      }
      assert_equal 1, Sidekiq.redis { |c| c.zcard('schedule') }
    end

    it 'discards non critical information about the message' do
      5.times {|i|
        msg = Sidekiq.dump_json('class' => CustomUniqueWorker.to_s, 'args' => ['something', false], 'sent_at' => (Time.now + i*60).to_f)
        actor = MiniTest::Mock.new
        actor.expect(:processor_done, nil, [@processor])
        actor.expect(:real_thread, nil, [nil, Celluloid::Thread])
        2.times { @boss.expect(:async, actor, []) }
        work = UnitOfWork.new('default', msg)
        @processor.process(work)
      }
      assert_equal 1, Sidekiq.redis { |c| c.zcard('schedule') }
    end

    it 'allows a job to be rescheduled when processing using unlock' do
      5.times {
        msg = Sidekiq.dump_json('class' => CustomUniqueWorker.to_s, 'args' => ['something', true])
        actor = MiniTest::Mock.new
        actor.expect(:processor_done, nil, [@processor])
        actor.expect(:real_thread, nil, [nil, Celluloid::Thread])
        2.times { @boss.expect(:async, actor, []) }
        work = UnitOfWork.new('default', msg)
        @processor.process(work)
      }
      assert_equal 5, Sidekiq.redis { |c| c.zcard('schedule') }
    end

  end
end
