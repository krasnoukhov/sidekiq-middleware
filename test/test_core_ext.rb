require 'helper'
require 'sidekiq-middleware'

class TestCoreExt < MiniTest::Unit::TestCase
  describe 'for an empty array' do
    it 'should be an empty hash' do
      assert_equal({}, {:foo => "bar"}.slice([]))
    end
  end

  describe 'for items not in the hash' do
    it 'should be an empty hash' do
      assert_equal({}, {:foo => "bar", :foobar => "baz"}.slice(:baz, :foobaz))
    end
  end

  describe 'for items in the hash' do
    it 'should be the attributes' do
      assert_equal({:foo => "bar"}, {:foo => "bar", :foobar => "baz"}.slice(:foo))
    end
  end

  describe 'for keys in the hash' do
    it 'should be the attributes' do
      assert_equal({:foo => nil}, {:foo => nil, :foobar => "baz"}.slice(:foo))
    end
  end

  describe 'when all items are in the hash' do
    it 'should be the hash' do
      assert_equal({:foo => "bar", :foobar => "baz"}, {:foo => "bar", :foobar => "baz"}.slice(:foo, :foobar))
    end
  end
end
