# frozen_string_literal: true

require 'sent_message'
##
# This class represents an unsent message
class Message
  attr_reader :id_recv, :i18nkey, :i18nparams, :markup

  def initialize(opts)
    @id_recv = opts[:id_recv]
    @i18nkey = opts[:i18nkey]
    @i18nparams = opts[:i18nparams]
    @markup = opts[:markup]
  end

  def new_id_recv(new_id_recv)
    Message.new(
      id_recv: new_id_recv,
      i18nkey: @i18nkey,
      i18nparams: @i18nparams,
      markup: @markup
    )
  end

  def new_i18nkey(new_i18nkey)
    Message.new(
      id_recv: @id_recv,
      i18nkey: new_i18nkey,
      i18nparams: @i18nparams,
      markup: @markup
    )
  end

  def new_i18nparams(new_i18nparams)
    Message.new(
      id_recv: @id_recv,
      i18nkey: @i18nkey,
      i18nparams: new_i18nparams,
      markup: @markup
    )
  end

  def new_markup(new_markup)
    Message.new(
      id_recv: @id_recv,
      i18nkey: @i18nkey,
      i18nparams: @i18nparams,
      markup: new_markup
    )
  end

  def send(api)
    rsp_obj = api.send_message(
      chat_id: @id_recv,
      text: I18n.t(
        @i18nkey,
        @i18nparams
      ),
      reply_markup: @markup
    )
    msg_obj = rsp_obj['result']
    SentMessage.new(
      id_revc: msg_obj['chat']['id'],
      datetime: msg_obj['date'],
      id: msg_obj['message_id'],
      i18nkey: @i18nkey,
      i18nparams: @i18nparams
    )
  end
end
