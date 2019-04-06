# frozen_string_literal: true

require 'messages/broadcast_message'
require 'messages/sent_message'
##
# This class represents an unsent message
class Message
  @bmsg = nil
  def initialize(opts)
    @bmsg = BroadcastMessage.new(
      recv_list: [opts[:id_recv]],
      i18nkey: opts[:i18nkey],
      i18nparams: opts[:i18nparams],
      markup: opts[:markup]
    )
  end

  def id_recv
    @bmsg.recv_list.first
  end

  def i18nkey
    @bmsg.i18nkey
  end

  def i18nparams
    @bmsg.i18nparams
  end

  def markup
    @bmsg.markup
  end

  def new_id_recv(new_id_recv)
    Message.new(
      id_recv: new_id_recv,
      i18nkey: i18nkey,
      i18nparams: i18nparams,
      markup: markup
    )
  end

  def new_i18nkey(new_i18nkey)
    Message.new(
      id_recv: id_recv,
      i18nkey: new_i18nkey,
      i18nparams: i18nparams,
      markup: markup
    )
  end

  def new_i18nparams(new_i18nparams)
    Message.new(
      id_recv: id_recv,
      i18nkey: i18nkey,
      i18nparams: new_i18nparams,
      markup: markup
    )
  end

  def new_markup(new_markup)
    Message.new(
      id_recv: id_recv,
      i18nkey: i18nkey,
      i18nparams: i18nparams,
      markup: new_markup
    )
  end

  def send(api)
    @bmsg.send(api)
  end
end
