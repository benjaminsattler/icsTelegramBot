# frozen_string_literal: true

require 'bot'
require 'statistics'
require 'message_log'
require 'setup/test_api'
require 'setup/test_persistence'

RSpec.describe Bot do
  describe 'is_admin_user' do
    it 'returns false for users that are not in the list of admin users' do
      bot = described_class.new('foo', ['123'], {}, {})
      expect(bot.admin_user?(122)).to eq(false)
    end

    it 'returns true for users that are in the list of admin users' do
      bot = described_class.new('foo', ['123'], {}, {})
      expect(bot.admin_user?(123)).to eq(true)
    end
  end

  describe 'run' do
    it 'calls run of api parameter' do
      bot = described_class.new(
        'foo',
        ['123'],
        Statistics.new,
        MessageLog.new(TestPersistence.new)
      )
      th = Thread.new do
        bot.run TestApi.new
      end
      sleep 3
      th[:stop] = true
    end
  end
end
