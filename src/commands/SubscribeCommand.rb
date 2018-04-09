require 'commands/command'
require 'commands/mixins/EventMessagePusher'

require 'i18n'

class SubscribeCommand < Command
    include EventMessagePusher

    def process(msg, userid, chatid, silent)
        isSubbed = self.dataStore.getSubscriberById(userid)
        if (isSubbed.nil?) then 
            self.dataStore.addSubscriber({telegram_id: userid, notificationday: 1, notificationtime: {hrs: 20, min: 0}, notifiedEvents: []})
            self.bot.pushMessage(I18n.t('confirmations.subscribe_success'), chatid)
            self.pushEventsDescription(self.calendars[1].getEvents(1), userid, chatid)
        else
            self.bot.pushMessage(I18n.t('errors.subscribe.double_subscription'), chatid);
        end
    end
end
