require 'commands/command'
require 'Container'

require 'i18n'

class BotStatusCommand < Command
  def process(chatid, silent = false)
    calendars = Container.get(:calendars)
    dataStore = Container.get(:dataStore)
    bot = Container.get(:bot)
    text = []
    text << I18n.t('botstatus.intro', uptime: bot.uptime_start.strftime('%d.%m.%Y %H:%M:%S'), calendar_count: calendars.keys.length)
    calendars.each_pair do |calendar_id, calendar|
      events_count = calendar[:eventlist].getEvents.length
      subscribers_count = dataStore.getAllSubscribers(calendar_id).length
      text << I18n.t('botstatus.calendar_info', calendar_id: calendar_id, calendar_name: calendar[:description], event_count: events_count, subscribers_count: subscribers_count)
    end
    @messageSender.process(text.join("\n"), chatid, nil, silent)
  end
end
