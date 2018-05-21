require 'commands/command'
require 'Container'

require 'i18n'

class BotStatusCommand < Command
    def process(msg, userid, chatid)
        calendars = Container::get(:calendars)
        dataStore = Container::get(:dataStore)
        bot = Container::get(:bot)
        text = Array.new
        text << I18n.t('botstatus.intro', uptime: bot.uptime_start.strftime('%d.%m.%Y %H:%M:%S'), calendar_count: calendars.length)
        calendars.each do |calendar|
            events_count = calendar[:eventlist].getEvents.length
            subscribers_count = dataStore.getAllSubscribers(calendar[:calendar_id]).length
            text << I18n.t('botstatus.calendar_info', calendar_id: calendar[:calendar_id], calendar_name: calendar[:description], event_count: events_count, subscribers_count: subscribers_count)
        end
        @messageSender.process(text.join("\n"), chatid)
    end
end
