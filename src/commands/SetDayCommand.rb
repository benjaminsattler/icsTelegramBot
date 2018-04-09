require 'commands/command'
require 'query/SetDayQuery'
require 'util'

require 'i18n'

class SetDayCommand < Command
    def process(msg, userid, chatid, silent)
        command, *args = msg.split(/\s+/)
        subscriber = @dataStore.getSubscriberById(userid)
        if subscriber.nil? then
            @bot.pushMessage(I18n.t('errors.no_subscription_teaser', command: '/setday'), chatid)
        else
            if args.empty? then
                inline = SetDayQuery.new({user_id: userid, chat_id: chatid, bot: @bot})
                inline.start
                return
            else
                days = 1
                if /^[0-9]+$/.match(args.first) then
                    days = args.first.to_i
                else
                    @bot.pushMessage(I18n.t('errors.setday.command_invalid'), chatid)
                    return
                end
        
                if days > 14 then
                    @bot.pushMessage(I18n.t('errors.setday.day_too_early'), chatid)
                    return
                end
                if days < 0 then
                    @bot.pushMessage(I18n.t('errors.setday.day_in_past'), chatid)
                    return
                end
        
                subscriber[:notificationday] = days
                subscriber[:notifiedEvents].clear
                @dataStore.updateSubscriber(subscriber)
                reminder_time = "#{pad(subscriber[:notificationtime][:hrs], 2)}:#{pad(subscriber[:notificationtime][:min], 2)}"
                if subscriber[:notificationday] == 0 then
                    @bot.pushMessage(I18n.t('confirmations.setdatetime_success_sameday', reminder_time: reminder_time), chatid)
                elsif subscriber[:notificationday] == 1 then
                    @bot.pushMessage(I18n.t('confirmations.setdatetime_success_precedingday', reminder_time: reminder_time), chatid)
                else
                    @bot.pushMessage(I18n.t('confirmations.setdatetime_success_otherday', reminder_day_count: subscriber[:notificationday], reminder_time: reminder_time), chatid)
                end
            end
        end
    end
end
