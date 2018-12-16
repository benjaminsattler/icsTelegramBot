# frozen_string_literal: true

require 'message_broadcaster'

RSpec.describe MessageBroadcaster do
  describe 'process' do
    let(:message_sender) { instance_double('MessageSender') }
    let(:persistence) { instance_double('Mysql') }
    let(:expected_message) { 'this is a broadcast test' }
    let(:calendars) do
      {
        1 => [{ telegram_id: 1 }, { telegram_id: 2 }],
        2 => [{ telegram_id: 2 }, { telegram_id: 3 }]
      }
    end

    it 'broadcasts to all subscribers of all eventlists' do
      allow(persistence).to receive(:calendars) { calendars }
      allow(persistence).to receive(:all_subscribers) { |p| calendars[p] }

      allow(message_sender).to receive(:process) do |*actual|
        actual_text = actual[0]
        actual_userid = actual[1]
        actual_markup = actual[2]
        actual_silent = actual[3]
        expect(actual_text).to eq(expected_message)
        expect([1, 2, 3].find(actual_userid)).not_to be_nil
        expect(actual_markup).to be nil
        expect(actual_silent).to be false
      end

      message_broadcaster = described_class.new(message_sender, persistence)
      message_broadcaster.process(expected_message)
    end

    it 'only texts once to subscribers' do
      allow(persistence).to receive(:calendars) { calendars }
      allow(persistence).to receive(:all_subscribers) { |p| calendars[p] }

      seen = []
      allow(message_sender).to receive(:process) do |*actual|
        actual_userid = actual[1]
        expect(seen).not_to include(actual_userid)
        seen.push actual_userid
      end

      message_broadcaster = described_class.new(message_sender, persistence)
      message_broadcaster.process(expected_message)
    end

    it 'broadcasts the message it got as a parameter' do
      allow(persistence).to receive(:calendars) { calendars }
      allow(persistence).to receive(:all_subscribers) { |p| calendars[p] }

      allow(message_sender).to receive(:process) do |*actual|
        actual_text = actual[0]
        expect(actual_text).to eq(expected_message)
      end

      message_broadcaster = described_class.new(message_sender, persistence)
      message_broadcaster.process(expected_message)
    end

    it 'does not send a message when called with an empty text' do
      allow(message_sender).to receive(:process) { raise('process called') }
      message_broadcaster = described_class.new(message_sender, persistence)
      message_broadcaster.process('')
    end
  end
end
