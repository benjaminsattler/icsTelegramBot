# frozen_string_literal: true

require 'i18n'
require 'messages/sent_message'
##
# This class represents an unsent broadcast message
class BroadcastMessage
  attr_reader :i18nkey, :i18nparams, :markup, :recv_list

  def initialize(opts)
    @i18nkey = opts[:i18nkey]
    @i18nparams = opts[:i18nparams]
    @markup = opts[:markup]
    @recv_list = opts[:recv_list]
  end

  def new_i18nkey(new_i18nkey)
    BroadcastMessage.new(
      recv_list: @recv_list,
      i18nkey: new_i18nkey,
      i18nparams: @i18nparams,
      markup: @markup
    )
  end

  def new_i18nparams(new_i18nparams)
    BroadcastMessage.new(
      recv_list: @recv_list,
      i18nkey: @i18nkey,
      i18nparams: new_i18nparams,
      markup: @markup
    )
  end

  def new_markup(new_markup)
    BroadcastMessage.new(
      recv_list: @recv_list,
      i18nkey: @i18nkey,
      i18nparams: @i18nparams,
      markup: new_markup
    )
  end

  def new_recv_list(new_recv_list)
    BroadcastMessage.new(
      recv_list: new_recv_list,
      i18nkey: @i18nkey,
      i18nparams: @i18nparams,
      markup: @markup
    )
  end

  def send(api)
    @recv_list.map do |recv|
      send_one(api, recv)
    end
  end

  def send_one(api, recv)
    rsp_obj = api.send_message(
      chat_id: recv,
      text: I18n.t(
        @i18nkey,
        @i18nparams
      ),
      reply_markup: @markup
    )
    msg_obj = rsp_obj['result']
    SentMessage.new(
      id_recv: msg_obj['chat']['id'],
      datetime: msg_obj['date'],
      id: msg_obj['message_id'],
      i18nkey: @i18nkey,
      i18nparams: @i18nparams
    )
  end
end
