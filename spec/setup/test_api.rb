# frozen_string_literal: true

require 'api_interface'

##
# This class will be used for tests against the
# telegram bot api.
class TestApi < ApiInterface
  attr_accessor :sent_msgs
  def initialize(sent_msgs = [])
    @sent_msgs = sent_msgs
  end

  def send_message(params)
    message_id = Random.rand(2**31)
    params[:message_id] = message_id
    @sent_msgs.push params
    msg = {
      'message_id' => message_id,
      'from' => {
        'id' => 1
      },
      'date' => Time.new.to_i,
      'chat' => {
        'id' => params[:chat_id]
      },
      'text' => params[:text]
    }
    wrap msg
  end

  def edit_message_buttons(params)
    idx = @sent_msgs
          .find_index { |msg| msg[:message_id] == params[:message_id] }
    @sent_msgs[idx][:reply_markup] = params[:reply_markup] unless idx.nil?
  end

  def edit_message_text(params)
    idx = @sent_msgs
          .find_index { |msg| msg[:message_id] == params[:message_id] }
    @sent_msgs[idx][:text] = params[:text] unless idx.nil?
  end

  def send_document(_params)
    raise NotImplementedError
  end

  def get_file(_params)
    raise NotImplementedError
  end

  def listen
    yield message
  end

  def message
    {
      text: 'hallo',
      from: {
        id: 42
      },
      chat: {
        id: 43
      }
    }
  end

  # rubocop:disable Naming/AccessorMethodName
  def get_identity
    msg = {
      'username' => 'TestImplementation'
    }
    wrap(msg)
  end
  # rubocop:enable Naming/AccessorMethodName

  def run(_token)
    yield TestApi.new
  end

  def wrap(msg)
    {
      'ok' => true,
      'result' => msg
    }
  end

  def push_sent_message_to_stack(sent_message, reply_markup = nil)
    msg = {
      chat_id: sent_message.id_recv,
      text: I18n.t(
        sent_message.i18nkey,
        sent_message.i18nparams
      ),
      reply_markup: reply_markup,
      message_id: sent_message.id
    }
    @sent_msgs.push(msg)
    msg
  end
end
