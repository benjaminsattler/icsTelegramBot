require 'i18n'
require 'Container'

module EventMessagePusher
    def pushEventsDescription(calendar_id, eventcount, userid, chatid)
        calendars = Container::get(:calendars)
        events = calendars[calendar_id][:eventlist].getEvents(eventcount)
        calendar_name = calendars[calendar_id][:description]
        text = Array.new
        text << I18n.t('events.listing_intro_multiple', total:eventcount, calendar_name: calendar_name) unless eventcount == 1
        text << I18n.t('events.listing_intro_one', calendar_name: calendar_name) if eventcount == 1
        text << I18n.t('events.listing_intro_empty', calendar_name: calendar_name) if eventcount == 0
        @messageSender.process(text.join("\n"), chatid)
        events
            .take(eventcount)
            .each { |event|  self.pushEventDescription(event, chatid)}
    end

    def pushEventDescription(event, chatid)
        @messageSender.process("#{event.date.strftime('%d.%m.%Y')}: #{event.summary}", chatid)
    end
end
