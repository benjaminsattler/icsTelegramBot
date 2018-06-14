# frozen_string_literal: true

require 'i18n'
require 'container'

##
# This module provides a mixing for pushing
# event information to the user.
module EventMessagePusher
  def push_events_description(calendar_id, eventcount, _userid, chatid)
    calendars = Container.get(:calendars)
    events = calendars[calendar_id][:eventlist].events(eventcount)
    calendar_name = calendars[calendar_id][:description]
    text = []
    unless eventcount == 1
      text << I18n.t(
        'events.listing_intro_multiple',
        total: eventcount,
        calendar_name: calendar_name
      )
    end
    if eventcount == 1
      text << I18n.t(
        'events.listing_intro_one',
        calendar_name: calendar_name
      )
    end
    if eventcount.zero?
      text << I18n.t(
        'events.listing_intro_empty',
        calendar_name: calendar_name
      )
    end
    @message_sender.process(text.join("\n"), chatid)
    events
      .take(eventcount)
      .each { |event| push_event_description(event, chatid) }
  end

  def push_event_description(event, chatid)
    @message_sender.process(
      "#{event.date.strftime('%d.%m.%Y')}: #{event.summary}",
      chatid
    )
  end
end
