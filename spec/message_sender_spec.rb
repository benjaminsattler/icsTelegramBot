# frozen_string_literal: true

require 'message_sender'

RSpec.describe MessageSender do
  describe 'default_keyboard_markup' do
    it 'includes admin actions for admin users' do
      bot = instance_double('Bot', admin_user?: true)
      statistics = instance_double('Statistics', sent_msg: nil)
      message_sender = described_class.new(bot, statistics)
      actual = message_sender.default_keyboard_markup(123)
      expect(actual.flatten).to include('/botstatus')
      expect(actual.flatten).to include('/broadcast')
    end

    it 'omits admin actions for regular users' do
      bot = instance_double('Bot', admin_user?: false)
      statistics = instance_double('Statistics', sent_msg: nil)
      message_sender = described_class.new(bot, statistics)
      actual = message_sender.default_keyboard_markup(123)
      expect(actual.flatten).not_to include('/botstatus')
      expect(actual.flatten).not_to include('/broadcast')
    end
  end

  describe 'process' do
    it 'updates statistics correctly' do
      api = instance_double('api', send_message: nil)
      bot_instance = instance_double('bot_instance', api: api)
      bot = instance_double('Bot', bot_instance: bot_instance)
      statistics = instance_double('Statistics', sent_msg: nil)
      message_sender = described_class.new(bot, statistics)
      allow(statistics).to receive(:sent_msg)
      message_sender.process('foo', 123, 456, false)
    end
  end
end
