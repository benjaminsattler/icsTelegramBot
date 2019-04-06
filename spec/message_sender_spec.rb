# frozen_string_literal: true

require 'message_sender'
require 'messages/message'
require 'message_log'
require 'setup/test_api'

RSpec.describe MessageSender do
  let(:api) { TestApi.new }
  let(:bot) { instance_double('Bot', bot_instance: api) }
  let(:statistics) { instance_double('Statistics', sent_msg: nil) }
  let(:message_log) { instance_double('MessageLog', add: nil) }

  describe 'process' do
    it 'updates statistics correctly' do
      message_sender = described_class.new(bot, api, statistics, message_log)
      msg = Message.new(
        id_recv: 123,
        i18nkey: 'foo',
        i18nparams: {},
        markup: nil
      )
      message_sender.process(msg)
      expect(statistics).to have_received(:sent_msg).once
    end

    it 'transmits a message' do
      message_sender = described_class.new(bot, api, statistics, message_log)
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

    it 'logs sent message' do
      message_sender = described_class.new(bot, api, statistics, message_log)
      msg = Message.new(
        id_recv: 123,
        i18nkey: 'foo',
        i18nparams: {},
        markup: nil
      )

      result = message_sender.process(msg)
      expect(message_log).to have_received(:add).with(result.first)
    end
  end
end
