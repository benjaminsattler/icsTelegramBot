# frozen_string_literal: true

require 'api_interface'

##
# This class will be used for tests against the
# telegram bot api.
class TestApi < ApiInterface
  attr_accessor :sent_msgs
  def initialize
    @sent_msgs = []
  end

  def send_message(params)
    @sent_msgs.push params
    msg = {
      'message_id' => Random.rand(2**31),
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

  def edit_message_reply_markup(_params)
    raise NotImplementedError
  end

  def edit_message_text(_params)
    raise NotImplementedError
  end

  def send_document(_params)
    raise NotImplementedError
  end

  def get_file(_params)
    raise NotImplementedError
  end

  def listen
    raise NotImplementedError
  end

  # rubocop:disable Naming/AccessorMethodName
  def get_me
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
end
