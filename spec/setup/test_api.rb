# frozen_string_literal: true

require 'api_interface'

##
# This class will be used for tests against the
# telegram bot api.
class TestApi < ApiInterface
  def send_message(opts)
    msg = {
      'message_id' => Random.rand(2**31),
      'from' => {
        'id' => 1
      },
      'date' => Time.new.to_i,
      'chat' => {
        'id' => opts[:chat_id]
      },
      'text' => opts[:text]
    }
    wrap msg
  end

  def wrap(msg)
    {
      'ok' => true,
      'result' => msg
    }
  end
end
