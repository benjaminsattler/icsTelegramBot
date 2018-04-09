require 'commands/command'
require 'query/SetTimeQuery'
require 'util'

require 'i18n'

class SetTimeCommand < Command
    def process(msg, userid, chatid, silent)
        command, *args = msg.split(/\s+/)
        subscriber = @dataStore.getSubscriberById(userid)
        if subscriber.nil? then
            @bot.pushMessage(I18n.t('errors.no_subscription_teaser', command: '/settime'), chatid)
        else
            hrs = 20
            min = 0
            matcher = /^([0-9]+):([0-9]+)$/.match(args.first)
            if args.first.nil? then
                inline = SetTimeQuery.new({user_id: userid, chat_id: chatid, bot: @bot})
                inline.start
                return
            else
                if !matcher.nil? then
                    if matcher[1].to_i >= 0 && matcher[1].to_i <= 23 && matcher[2].to_i >= 0 &&  matcher[2].to_i <= 59 then
                        hrs = matcher[1].to_i
                        min = matcher[2].to_i
                        subscriber[:notificationtime] = {hrs: hrs, min: min}
                        subscriber[:notifiedEvents].clear
                        @dataStore.updateSubscriber(subscriber)
                        reminder_time ="#{pad(subscriber[:notificationtime][:hrs], 2)}:#{pad(subscriber[:notificationtime][:min], 2)}"
                        if subscriber[:notificationday] == 0 then
                            @bot.pushMessage(I18n.t('confirmations.setdatetime_success_sameday', reminder_time: reminder_time), chatid)
                        elsif subscriber[:notificationday] == 1 then
                            @bot.pushMessage(I18n.t('confirmations.setdatetime_success_precedingday', reminder_time: reminder_time), chatid)
                        else
                            @bot.pushMessage(I18n.t('confirmations.setdatetime_success_otherday', reminder_day_count: subscriber[:notificationday], reminder_time: reminder_time), chatid)
                        end
                        return
                    end
                end
                @bot.pushMessage(I18n.t('errors.settime.command_invalid'), chatid)
            end
        end
    end
end
