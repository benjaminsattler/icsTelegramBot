require 'commands/command'
require 'commands/mixins/EventMessagePusher'

require 'i18n'

class SubscribeCommand < Command
    include EventMessagePusher

    def process(msg, userid, chatid, silent)
        isSubbed = @dataStore.getSubscriberById(userid)
        if (isSubbed.nil?) then 
            @dataStore.addSubscriber({telegram_id: userid, notificationday: 1, notificationtime: {hrs: 20, min: 0}, notifiedEvents: []})
            @bot.pushMessage(I18n.t('confirmations.subscribe_success'), chatid)
            self.pushEventsDescription(@calendars[1].getEvents(1), userid, chatid)
        else
            self.pushMessage(I18n.t('errors.subscribe.double_subscription'), chatid);
        end
    end
end
