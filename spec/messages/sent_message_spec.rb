# frozen_string_literal: true

require 'messages/sent_message'
require 'setup/test_api'

RSpec.describe SentMessage do
  let(:sent_message_id) { Random.rand(2**31) }
  let(:sent_message) do
    described_class.new(
      id_revc: 42,
      datetime: Time.new.to_i,
      id: sent_message_id,
      i18nkey: 'i18nkey',
      i18nparams: {
        param1: 'foo',
        param2: 43
      }
    )
  end

  it 'forbids reassignment' do
    expect { sent_message.id_recv = 2 }.to raise_error(NoMethodError)
    expect { sent_message.datetime = 1 }.to raise_error(NoMethodError)
    expect { sent_message.id = 2 }.to raise_error(NoMethodError)
    expect { sent_message.i18nkey = 'foo' }.to raise_error(NoMethodError)
    expect { sent_message.i18nparams = {} }.to raise_error(NoMethodError)
  end

  describe 'set_markup' do
    it 'changes the markup' do
      api = TestApi.new
      api.push_sent_message_to_stack(sent_message)
      sent_message.set_markup(api, ['/foo'])
      actual_markup = api.sent_msgs.pop[:reply_markup]
      expect(actual_markup.inline_keyboard).to eq([['/foo']])
    end
  end

  describe 'clear_markup' do
    it 'clears the markup' do
      api = TestApi.new
      api.push_sent_message_to_stack(sent_message, ['/foo'])
      sent_message.clear_markup(api)
      actual_markup = api.sent_msgs.pop[:reply_markup]
      expect(actual_markup).to be_instance_of(
        Telegram::Bot::Types::ReplyKeyboardRemove
      )
    end
  end

  describe 'set_text' do
    it 'changes the message text' do
      api = TestApi.new
      new_i18nkey = 'newkey'
      new_i18nparams = {
        param1: 'foo'
      }
      api.push_sent_message_to_stack(sent_message)
      sent_message.set_text(
        api,
        new_i18nkey,
        new_i18nparams
      )
      actual = api.sent_msgs.pop
      expected = I18n.t(
        new_i18nkey,
        new_i18nparams
      )
      expect(actual[:text]).to eq(expected)
    end

    it 'updates the sent message object' do
      api = TestApi.new
      new_i18nkey = 'newkey'
      new_i18nparams = {
        param1: 'foo'
      }
      api.push_sent_message_to_stack(sent_message)
      sent_message.set_text(
        api,
        new_i18nkey,
        new_i18nparams
      )
      expect(sent_message.i18nkey).to eq(new_i18nkey)
      expect(sent_message.i18nparams).to eq(new_i18nparams)
    end
  end
end
