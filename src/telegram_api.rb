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

  def edit_message_reply_markup(params)
    @handle.api.edit_message_reply_markup(params)
  end

  def edit_message_text(params)
    @handle.api.edit_message_text(params)
  end

  def send_message(params)
    @handle.api.send_message(params)
  end

  def send_document(params)
    @handle.api.send_document(params)
  end

  def get_file(params)
    @handle.api.get_file(params)
  end

  def listen
    @handle.listen do |bot|
      yield(bot)
    end
  end

  # rubocop:disable Naming/AccessorMethodName
  def get_me
    @handle.api.get_me
  end
  # rubocop:enable Naming/AccessorMethodName

  def self.run(token)
    Telegram::Bot::Client.run(token) do |bot|
      yield TelegramApi.new(bot)
    end
  end
end
