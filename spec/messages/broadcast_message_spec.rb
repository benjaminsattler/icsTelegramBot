# frozen_string_literal: true

require 'messages/broadcast_message'
require 'setup/test_api'
require 'i18n'

RSpec.describe BroadcastMessage do
  let(:api) { TestApi.new }
  let(:message) do
    described_class.new(
      recv_list: [42, 43],
      i18nkey: 'i18nkey',
      i18nparams: {
        param1: 'foo',
        param2: 43
      },
      markup: nil
    )
  end

  describe 'new_recv_list' do
    it 'returns a new instance' do
      actual = message.new_recv_list([43, 44])
      expect(actual.recv_list).not_to equal(message.recv_list)
    end

    it 'sets the new value' do
      new_value = [43, 44]
      actual = message.new_recv_list(new_value)
      expect(actual.recv_list).to equal(new_value)
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
      new_value = {}
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
    it 'returns a list of new SentMessage object' do
      actual = message.send(api)
      expect(actual.class).to equal(Array)
      actual.each do |item|
        expect(item.class).to equal(SentMessage)
      end
    end

    it 'returns a SentMessage for each recipient' do
      actual = message.send(api)
      expect(actual.length).to eq(message.recv_list.length)
    end

    it 'returns correct SentMessage objects' do
      before_time = Time.new.to_i
      actual = message.send(api)
      after_time = Time.new.to_i
      message.recv_list.each_index do |i|
        expect(actual[i].id_recv).to equal(message.recv_list[i])
        expect(actual[i].i18nkey).to equal(message.i18nkey)
        expect(actual[i].i18nparams).to equal(message.i18nparams)
        expect(before_time..after_time).to cover(actual[i].datetime)
      end
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
      actual = api.sent_msgs
                  .pop(message.recv_list.length)
                  .map { |e| e[:chat_id] }
      expect(actual).to match_array(message.recv_list)
    end

    it 'sends the correct markup' do
      message.send(api)
      api.sent_msgs
         .pop(message.recv_list.length)
         .each do |e|
           expect(e[:reply_markup]).to eq(message.markup)
         end
    end
  end
end
