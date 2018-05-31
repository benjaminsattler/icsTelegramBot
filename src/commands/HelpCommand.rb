require 'commands/command'
require 'Container'

require 'i18n'

class HelpCommand < Command
  def process(_msg, _userid, chatid)
    calendars = Container.get(:calendars)
    text = []
    text << I18n.t('help.intro', calendars_count: calendars.keys.length)
    text << I18n.t('help.start')
    text << ''
    text << I18n.t('help.subscribe')
    text << I18n.t('help.unsubscribe')
    text << ''
    text << I18n.t('help.settime')
    text << I18n.t('help.setday')
    text << ''
    text << I18n.t('help.events')
    text << ''
    text << I18n.t('help.botstatus')
    text << I18n.t('help.mystatus')
    text << ''
    text << I18n.t('help.help')
    @messageSender.process(text.join("\n"), chatid)
  end
end
