# frozen_string_literal: true

require 'events/event'
require 'messages/notification'
require 'setup/test_api'
require 'setup/test_persistence'
require 'i18n'

RSpec.describe Notification do
  let(:summary) { 'Eventsummary' }
  let(:event) do
    event = Events::Event.new
    event.date = Date.today
    event.summary = summary
    event.id = 42
    event.calendar_id = 5
    event
  end
  let(:message_sender) do
    instance_double('MessageSender', process: nil)
  end
  let(:persistence) { TestPersistence.new }

  let(:message) do
    described_class.new(
      recv: {
        telegram_id: 42
      },
      event: event,
      calendar: {},
      message_sender: message_sender,
      persistence: persistence
    )
  end
  let(:api) { TestApi.new }

  describe 'send' do
    it 'returns an array of new SentMessage objects' do
      actual = message.send(api)
      expect(actual).to respond_to(:length)
      expect(actual).to all(be_instance_of(SentMessage))
    end

    it 'returns an array with only one message' do
      actual = message.send(api)
      expect(actual.length).to eq(1)
    end

    it 'returns correct SentMessage objects' do
      before_time = Time.new.to_i
      actual = message.send(api)[0]
      after_time = Time.new.to_i
      expect(actual.id_recv).to eq(message.id_recv)
      expect(actual.i18nkey).to eq(message.i18nkey)
      expect(actual.i18nparams).to eq(message.i18nparams)
      expect(before_time..after_time).to cover(actual.datetime)
    end

    it 'sends a message' do
      message.send(api)
      actual = api.sent_msgs.pop
      expect(actual).not_to be_nil
    end

    it 'sends the correct text' do
      message.send(api)
      actual = api.sent_msgs.pop
      expect(actual[:text]).to eq(
        I18n.t(
          'event.reminder',
          message.i18nparams
        )
      )
    end

    it 'addresses the correct user' do
      message.send(api)
      actual = api.sent_msgs.pop
      expect(actual[:chat_id]).to equal(message.id_recv)
    end

    it 'sends the correct markup' do
      message.send(api)
      actual = api.sent_msgs.pop
      expect(actual[:reply_markup]).to eq(nil)
    end

    it 'adds a notification to the notification log' do
      count_before = persistence.logged_notifications.length
      message.send(api)
      count_after = persistence.logged_notifications.length
      expect(count_after).to eq(count_before + 1)
    end

    it 'adds a correct notification to the notification log' do
      message.send(api)
      actual = persistence.logged_notifications.last
      expect(actual[:notification].id_recv).to eq(message.id_recv)
    end
  end
end
