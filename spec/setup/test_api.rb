# frozen_string_literal: true

require 'api_interface'

##
# This class will be used for tests against the
# telegram bot api.
class TestApi < ApiInterface
  def send_message(params)
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

  def send_document(_params)
    raise NotImplementedError
  end

  def wrap(msg)
    {
      'ok' => true,
      'result' => msg
    }
  end
end
