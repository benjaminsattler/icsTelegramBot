# frozen_string_literal: true

require 'messages/message'
require 'setup/test_api'
require 'i18n'

RSpec.describe Message do
  let(:api) { TestApi.new }
  let(:message) do
    described_class.new(
      id_recv: 42,
      i18nkey: 'i18nkey',
      i18nparams: {
        param1: 'foo',
        param2: 43
      },
      markup: nil
    )
  end

  describe 'new_id_recv' do
    it 'returns a new instance' do
      actual = message.new_id_recv(43)
      expect(actual.id_recv).not_to equal(message.id_recv)
    end

    it 'sets the new value' do
      new_value = 43
      actual = message.new_id_recv(new_value)
      expect(actual.id_recv).to equal(new_value)
    end
  end

  describe 'new_i18nkey' do
    it 'returns a new instance' do
      actual = message.new_i18nkey('newkey')
      expect(actual.i18nkey).not_to equal(message.i18nkey)
    end

    it 'sets the new value' do
      new_value = 'newkey'
      actual = message.new_i18nkey(new_value)
      expect(actual.i18nkey).to equal(new_value)
    end
  end

  describe 'new_i18nparams' do
    it 'returns a new instance' do
      actual = message.new_i18nparams({})
      expect(actual.i18nparams).not_to equal(message.i18nparams)
    end

    it 'sets the new value' do
      new_value = { a: 'b' }
      actual = message.new_i18nparams(new_value)
      expect(actual.i18nparams).to eq(new_value)
    end
  end

  describe 'new_markup' do
    it 'returns a new instance' do
      actual = message.new_markup({})
      expect(actual.markup).not_to equal(message.markup)
    end

    it 'sets the new value' do
      new_value = {}
      actual = message.new_markup(new_value)
      expect(actual.markup).to equal(new_value)
    end
  end

  describe 'send' do
    it 'returns a new SentMessage object' do
      actual = message.send(api)
      expect(actual.class).to equal(SentMessage)
    end

    it 'returns correct SentMessage object' do
      before_time = Time.new.to_i
      actual = message.send(api)
      after_time = Time.new.to_i
      expect(actual.id_recv).to equal(message.id_recv)
      expect(actual.i18nkey).to equal(message.i18nkey)
      expect(actual.i18nparams).to equal(message.i18nparams)
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
          message.i18nkey,
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
      expect(actual[:reply_markup]).to equal(message.markup)
    end
  end
end
