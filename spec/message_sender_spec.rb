# frozen_string_literal: true

require 'message_sender'
require 'messages/message'
require 'setup/test_api'

RSpec.describe MessageSender do
  let(:api) { TestApi.new }

  describe 'process' do
    it 'updates statistics correctly' do
      bot = instance_double('Bot', bot_instance: api)
      statistics = instance_double('Statistics', sent_msg: nil)
      message_sender = described_class.new(bot, api, statistics)
      allow(statistics).to receive(:sent_msg)
      msg = Message.new(
        id_recv: 123,
        i18nkey: 'foo',
        i18nparams: {},
        markup: nil
      )

      message_sender.process(msg)
    end

    it 'transmits a message' do
      bot = instance_double('Bot', bot_instance: api)
      statistics = instance_double('Statistics', sent_msg: nil)
      message_sender = described_class.new(bot, api, statistics)
      msg = Message.new(
        id_recv: 123,
        i18nkey: 'foo',
        i18nparams: {},
        markup: nil
      )

      msg_count_before = api.sent_msgs.size
      message_sender.process(msg)
      expect(api.sent_msgs.size).to equal(msg_count_before + 1)
    end
  end
end
