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
    text = []
    unless events.count == 1
      text << I18n.t(
        'events.listing_intro_multiple',
        total: eventcount,
        calendar_name: calendar_name
      )
    end
    if events.count == 1
      text << I18n.t(
        'events.listing_intro_one',
        calendar_name: calendar_name
      )
    end
    if events.count.zero?
      text << I18n.t(
        'events.listing_intro_empty',
        calendar_name: calendar_name
      )
    end
    text << ''
    events.each do |event|
      text << "#{event.date.strftime('%d.%m.%Y')}: #{event.summary}"
    end

    markup = nil
    if events.count.positive?
      text << ''
      text << I18n.t('events.listing_outro_more')
      markup = more_events_keyboard_markup(
        calendar_id,
        eventcount,
        eventcount + eventskip
      )
    end

    @message_sender.process(
      text.join("\n"),
      chatid,
      markup
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
