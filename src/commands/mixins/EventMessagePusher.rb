require 'i18n'

module EventMessagePusher
    def pushEventsDescription(events, userid, chatid)
        count = events.length
        text = Array.new
        text << I18n.t('events.listing_intro_multiple', total:count) unless count == 1
        text << I18n.t('events.listing_intro_one') if count == 1
        text << I18n.t('events.listing_intro_empty') if count == 0
        @bot.pushMessage(text.join("\n"), chatid)
        events
            .take(count)
            .each { |event|  self.pushEventDescription(event, chatid)}
    end

    def pushEventDescription(event, chatid)
        @bot.pushMessage("#{event.date.strftime('%d.%m.%Y')}: #{event.summary}", chatid)
    end
end
