# frozen_string_literal: true

require 'i18n'
require 'container'

##
# This module provides a mixing for pushing
# event information to the user.
module EventMessagePusher
  def push_events_description(
    calendar_id,
    eventcount,
    _userid,
    chatid,
    eventskip = 0
  )
    calendars = Container.get(:calendars)
    eventskip = 0 if eventskip.negative?
    events = calendars[calendar_id][:eventlist].events
                                               .drop(eventskip)
                                               .take(eventcount)
    calendar_name = calendars[calendar_id][:description]
    i18nkey = nil
    i18nparams = {}
    unless events.count == 1
      i18nkey = 'events.listing_multiple'
      i18nparams = {
        total: eventcount,
        calendar_name: calendar_name
      }
    end
    if events.count == 1
      i18nkey = 'events.listing_one'
      i18nparams = {
        calendar_name: calendar_name
      }
    end
    if events.count.zero?
      i18nkey = 'events.listing_empty'
      i18nparams = {
        calendar_name: calendar_name
      }
    end
    events_text = +''
    events.each do |event|
      events_text << "#{event.date.strftime('%d.%m.%Y')}: #{event.summary}\n"
    end

    i18nparams[:events] = events_text
    markup = nil
    if events.count.positive?
      markup = more_events_keyboard_markup(
        calendar_id,
        eventcount,
        eventcount + eventskip
      )
    end

    @message_sender.process(
      Message.new(
        i18nkey: i18nkey,
        i18nparams: i18nparams,
        id_recv: chatid,
        markup: markup
      )
    )
  end

  def more_events_keyboard_markup(calendar_id, event_count, event_skip)
    btn = Telegram::Bot::Types::InlineKeyboardButton.new(
      text: I18n.t('events.show_more_button', count: event_count),
      callback_data: "/events #{calendar_id} #{event_count} #{event_skip}"
    )

    Telegram::Bot::Types::InlineKeyboardMarkup.new(
      inline_keyboard: [[btn]]
    )
  end
end
