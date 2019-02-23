# frozen_string_literal: true

require 'message_sender'
require 'setup/test_api'

RSpec.describe MessageSender do
  let(:api) { TestApi.new }

  describe 'default_keyboard_markup' do
    it 'includes admin actions for admin users' do
      bot = instance_double('Bot', admin_user?: true)
      statistics = instance_double('Statistics', sent_msg: nil)
      message_sender = described_class.new(bot, api, statistics)
      actual = message_sender.default_keyboard_markup(123)
      expect(actual.flatten).to include('/botstatus')
      expect(actual.flatten).to include('/broadcast')
    end

    it 'omits admin actions for regular users' do
      bot = instance_double('Bot', admin_user?: false)
      statistics = instance_double('Statistics', sent_msg: nil)
      message_sender = described_class.new(bot, api, statistics)
      actual = message_sender.default_keyboard_markup(123)
      expect(actual.flatten).not_to include('/botstatus')
      expect(actual.flatten).not_to include('/broadcast')
    end
  end

  describe 'process' do
    it 'updates statistics correctly' do
      bot = instance_double('Bot', bot_instance: api)
      statistics = instance_double('Statistics', sent_msg: nil)
      message_sender = described_class.new(bot, api, statistics)
      allow(statistics).to receive(:sent_msg)
      message_sender.process('foo', 123, 456, false)
    end
  end
end
