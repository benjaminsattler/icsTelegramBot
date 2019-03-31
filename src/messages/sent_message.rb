# frozen_string_literal: true

##
# This class represents a delivered message to a telegram user
class SentMessage
  attr_reader :id_recv, :datetime, :id, :i18nkey, :i18nparams

  def initialize(opts)
    @id_recv = opts[:id_recv]
    @datetime = opts[:datetime]
    @id = opts[:id]
    @i18nkey = opts[:i18nkey]
    @i18nparams = opts[:i18nparams]
  end

  def set_markup(api, new_markup)
    api.edit_message_reply_markup(
      chat_id: @id_recv,
      message_id: @id,
      reply_markup: Telegram::Bot::Types::InlineKeyboardMarkup.new(
        inline_keyboard: new_markup
      )
    )
  end

  def clear_markup(api)
    api.edit_message_reply_markup(
      chat_id: @id_recv,
      message_id: @id,
      reply_markup: Telegram::Bot::Types::ReplyKeyboardRemove.new(
        remove_keyboard: true
      )
    )
  end

  def set_text(api, new_i18nkey, new_i18nparams)
    api.edit_message_text(
      chat_id: @id_recv,
      message_id: @id,
      text: I18n.t(
        new_i18nkey,
        new_i18nparams
      )
    )
    @i18nkey = new_i18nkey
    @i18nparams = new_i18nparams
    self
  end

  def self.from_message_log_sql(resource)
    SentMessage.new(
      id_recv: resource['telegram_id'],
      datetime: resource['message_timestamp'],
      id: resource['id_message_log'],
      i18nkey: resource['i18nkey'],
      i18nparams: resource['i18nparams']
    )
  end
end
