require 'commands/command'

require 'i18n'

class StartCommand < Command
    def process(msg, userid, chatid)
        bot = Container::get(:bot)
        @messageSender.process(I18n.t('start', botname: bot.bot_instance.api.getMe()['result']['username']), chatid)
    end
end
