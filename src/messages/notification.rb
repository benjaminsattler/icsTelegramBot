# frozen_string_literal: true

require 'messages/message'
require 'messages/sent_message'
##
# This class represents an unsent message
class Notification
  attr_reader :event, :calendar

  @i18nkey = 'event.reminder'
  @recv = nil
  @calendar = nil
  @event = nil
  @message_sender = nil
  @persistence = nil

  def initialize(opts)
    @recv = opts[:recv]
    @event = opts[:event]
    @calendar = opts[:calendar]
    @message_sender = opts[:message_sender]
    @persistence = opts[:persistence]
  end

  def id_recv
    @recv[:telegram_id]
  end

  def i18nkey
    'event.reminder'
  end

  def i18nparams
    description = @calendar[:description]
    summary = @event.summary
    days_to_event = @recv[:notificationday]
    date_of_event = @event.date.strftime('%d.%m.%Y')
    {
      summary: summary,
      calendar_name: description,
      days_to_event: days_to_event,
      date_of_event: date_of_event
    }
  end

  def markup
    nil
  end

  def new_recv(new_recv)
    Notification.new(
      recv: new_recv,
      event: @event,
      calendar: @calendar,
      message_sender: @message_sender,
      persistence: @persistence
    )
  end

  def send(api)
    message = Message.new(
      id_recv: id_recv,
      i18nkey: i18nkey,
      i18nparams: i18nparams,
      markup: nil
    )
    sent_messages = message.send(api)
    @persistence.add_to_notification_log(
      self,
      sent_messages.first.datetime
    )
    sent_messages
  end
end
