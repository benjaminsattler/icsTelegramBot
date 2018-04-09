require 'commands/command'

require 'i18n'

class HelpCommand < Command
    def process(msg, userid, chatid, silent)
        text = Array.new
        text << I18n.t('help.intro', last_event_date: self.calendars[1].getLeastRecentEvent.date.strftime("%d.%m.%Y"))
        text << I18n.t('help.start')
        text << ""
        text << I18n.t('help.subscribe')
        text << I18n.t('help.unsubscribe')
        text << ""
        text << I18n.t('help.settime')
        text << I18n.t('help.setday')
        text << ""
        text << I18n.t('help.events')
        text << ""
        text << I18n.t('help.botstatus')
        text << I18n.t('help.mystatus')
        text << ""
        text << I18n.t('help.help')
        self.bot.pushMessage(text.join("\n"), chatid)
    end
end
