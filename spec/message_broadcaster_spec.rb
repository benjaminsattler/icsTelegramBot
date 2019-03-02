# frozen_string_literal: true

require 'message_sender'
require 'bot'
require 'statistics'
require 'setup/test_api'
require 'message_broadcaster'
require 'messages/broadcast_message'

RSpec.describe MessageBroadcaster do
  let(:bot) { Bot.new('1', []) }
  let(:api) { TestApi.new }
  let(:message_sender) { MessageSender.new(bot, api, Statistics.new) }

  describe 'process' do
    it 'sends correct number of messages' do
      message_broadcaster = described_class.new(message_sender)
      recv_list = [1, 2]
      bmsg = BroadcastMessage.new(
        i18nkey: 'foo',
        i18nparams: {},
        markup: nil,
        recv_list: recv_list
      )
      count_before = api.sent_msgs.count
      message_broadcaster.process(bmsg)
      expect(api.sent_msgs.count).to eq(count_before + recv_list.count)
    end

    it 'sends a message to all recipients' do
      recv_list = [1, 2, 3]
      bmsg = BroadcastMessage.new(
        i18nkey: 'foo',
        i18nparams: {},
        markup: nil,
        recv_list: recv_list
      )
      message_broadcaster = described_class.new(message_sender)
      message_broadcaster.process(bmsg)
      actual_rcpt_ids = api.sent_msgs.map do |msg|
        msg[:chat_id]
      end
      expect(actual_rcpt_ids).to match_array(recv_list)
    end

    it 'broadcasts the message it got as a parameter' do
      recv_list = [1, 2, 3]
      bmsg = BroadcastMessage.new(
        i18nkey: 'foo',
        i18nparams: {},
        markup: nil,
        recv_list: recv_list
      )
      message_broadcaster = described_class.new(message_sender)
      message_broadcaster.process(bmsg)
      api.sent_msgs.each do |msg|
        expect(msg[:text]).to eq(I18n.t('foo'))
      end
    end

    it 'returns a list of SentMessages' do
      recv_list = [1, 2, 3]
      bmsg = BroadcastMessage.new(
        i18nkey: 'foo',
        i18nparams: {},
        markup: nil,
        recv_list: recv_list
      )
      message_broadcaster = described_class.new(message_sender)
      sent_messages = message_broadcaster.process(bmsg)
      expect(sent_messages).to respond_to(:length)
      expect(sent_messages).to all(be_instance_of(SentMessage))
    end

    it 'returns a list of correct length' do
      recv_list = [1, 2, 3]
      bmsg = BroadcastMessage.new(
        i18nkey: 'foo',
        i18nparams: {},
        markup: nil,
        recv_list: recv_list
      )
      message_broadcaster = described_class.new(message_sender)
      sent_messages = message_broadcaster.process(bmsg)
      expect(sent_messages.length).to equal(recv_list.length)
    end
  end
end
