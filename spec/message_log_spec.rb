# frozen_string_literal: true

require 'messages/sent_message'
require 'message_log'
require 'setup/test_persistence'

RSpec.describe MessageLog do
  let(:persistence) { TestPersistence.new }
  let(:message) do
    SentMessage.new(
      id_recv: 123,
      id: 42,
      i18nkey: 'foo',
      i18nparams: {},
      markup: nil,
      datetime: 4711
    )
  end

  describe 'add' do
    it 'persists the given message only once' do
      message_log = described_class.new(persistence)
      count_before = persistence.logged_messages.length
      message_log.add(message)
      count_after = persistence.logged_messages.length
      expect(count_after).to equal(count_before + 1)
    end

    it 'persists the correct message' do
      message_log = described_class.new(persistence)
      message_log.add(message)
      actual = persistence.logged_messages.pop
      expect(actual[:telegram_id]).to eq(message.id_recv)
      expect(actual[:msg_id]).to eq(message.id)
      expect(actual[:i18nkey]).to eq(message.i18nkey)
      expect(JSON.parse(actual[:i18nparams])).to eq(message.i18nparams)
      expect(actual[:message_timestamp]).to eq(message.datetime)
    end
  end
end
