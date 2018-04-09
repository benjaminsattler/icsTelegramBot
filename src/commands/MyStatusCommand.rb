require 'commands/command'
require 'util'

require 'i18n'

class MyStatusCommand < Command

    def process(msg, userid, chatid, silent)
        subscriber = self.dataStore.getSubscriberById(userid)
        if (subscriber.nil?) then 
            self.bot.pushMessage(I18n.t('status.not_subscribed'), chatid)
        else
            reminder_time = "#{pad(subscriber[:notificationtime][:hrs], 2)}:#{pad(subscriber[:notificationtime][:min], 2)}"
            if subscriber[:notificationday] == 0 then
                self.bot.pushMessage(I18n.t('status.subscribed_sameday', reminder_time: reminder_time), chatid)
            elsif subscriber[:notificationday] == 1 then
                self.bot.pushMessage(I18n.t('status.subscribed_precedingday', reminder_time: reminder_time), chatid)
            else
                self.bot.pushMessage(I18n.t('status.subscribed_otherday', reminder_day_count: subscriber[:notificationday], reminder_time: reminder_time), chatid)
            end
        end
    end
end
