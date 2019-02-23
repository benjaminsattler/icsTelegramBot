# frozen_string_literal: true

require 'api_interface'

##
# This interface serves as the base for implementations
# of the Telegram bot api as specified at
# https://core.telegram.org/bots/api
class TelegramApi < ApiInterface
  @handle = nil
  def initialize(http_handle)
    @handle = http_handle
  end

  def send_message(params)
    @handle.api.send_message(params)
  end

  def send_document(params)
    @handle.api.send_document(params)
  end
end
