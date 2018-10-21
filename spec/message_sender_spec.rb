# frozen_string_literal: true

require 'message_sender'

RSpec.describe MessageSender do
  describe 'default_keyboard_markup' do
    it 'includes admin actions for admin users' do
      bot = instance_double('Bot', admin_user?: true)
      message_sender = described_class.new(bot)
      actual = message_sender.default_keyboard_markup(123)
      expect(actual.flatten).to include('/botstatus')
    end

    it 'omits admin actions for regular users' do
      bot = instance_double('Bot', admin_user?: false)
      message_sender = described_class.new(bot)
      actual = message_sender.default_keyboard_markup(123)
      expect(actual.flatten).not_to include('/botstatus')
    end
  end
end
