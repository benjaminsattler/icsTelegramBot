require 'commands/command'

require 'i18n'

class BotStatusCommand < Command
    def process(msg, userid, chatid, silent)
        text = Array.new
        text << I18n.t('botstatus.uptime', uptime: self.bot.uptime_start.strftime('%d.%m.%Y %H:%M:%S'))
        self.calendars.each do |key, value|
            text << I18n.t('botstatus.event_count', event_count: value.getEvents.length)
            text << I18n.t('botstatus.subscribers_count', subscribers_count: self.dataStore.getAllSubscribers(key).length)
        end
        self.bot.pushMessage(text.join("\n"), chatid, nil, silent)
    end
end
