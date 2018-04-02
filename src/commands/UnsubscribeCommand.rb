require 'commands/command'

require 'i18n'

class UnsubscribeCommand < Command
    include EventMessagePusher

    def process(msg, userid, chatid, silent)
        @dataStore.removeSubscriber(userid)
        @bot.pushMessage(I18n.t('confirmations.unsubscribe_success'), chatid)
    end
end
