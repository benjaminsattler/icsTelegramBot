require 'commands/command'
require 'Container'
require 'util'

require 'i18n'

class MyStatusCommand < Command

    def process(msg, userid, chatid, silent)
        dataStore = Container::get(:dataStore)
        calendars = Container::get(:calendars)
        subscriptions = dataStore.getSubscriptionsForId(userid)
        if subscriptions.length == 0 then
            @messageSender.process(I18n.t('status.not_subscribed'), chatid)
            return
        end
        @messageSender.process(I18n.t('status.intro'), chatid)
        subscriptions.each do |subscription|
            reminder_time = "#{pad(subscription[:notificationtime][:hrs], 2)}:#{pad(subscription[:notificationtime][:min], 2)}"
            calendar_name = calendars[subscription[:eventlist_id]][:description]
            if subscription[:notificationday] == 0 then
                @messageSender.process(I18n.t('status.subscribed_sameday', reminder_time: reminder_time, calendar_name: calendar_name), chatid)
            elsif subscription[:notificationday] == 1 then
                @messageSender.process(I18n.t('status.subscribed_precedingday', reminder_time: reminder_time, calendar_name: calendar_name), chatid)
            else
                @messageSender.process(I18n.t('status.subscribed_otherday', reminder_day_count: subscription[:notificationday], reminder_time: reminder_time, calendar_name: calendar_name), chatid)
            end
        end
    end
end
