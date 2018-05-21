require 'commands/command'
require 'util'

require 'i18n'

class SetTimeCommand < Command
    def process(msg, userid, chatid, orig)
        command, *args = msg.split(/\s+/)
        calendars = Container::get(:calendars)
        dataStore = Container::get(:dataStore)
        calendar_id = args[0]
        bot = Container::get(:bot)
        time = args[1]
        if calendar_id.nil?
            @messageSender.process(I18n.t('settime.choose_calendar'), chatid, self.getCalendarButtons)
            return
        end
        calendar_id = Integer(calendar_id)
        if calendar_id > calendars.length or calendar_id < 0 or calendars[calendar_id].nil? then
            @messageSender.process(I18n.t('errors.settime.command_invalid'), chatid)
            return
        end
        begin
            bot.bot_instance.api.editMessageReplyMarkup(chat_id: orig.message.chat.id, message_id: orig.message.message_id, reply_markup: Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: []))
        rescue
        end
        subscriber = dataStore.getSubscriberById(userid, calendar_id)
        if subscriber.nil? then
            @messageSender.process(I18n.t('errors.no_subscription_teaser', command: '/settime'), chatid)
            return
        end
        response = I18n.t('settime.command_inline', response: time)
        if time.nil? then
            @messageSender.process(response, chatid, self.getTimeButtons(calendar_id, time))
            return
        end
        if time.length < 4 then
            begin
                bot.bot_instance.api.editMessageText(chat_id: orig.message.chat.id, message_id: orig.message.message_id, text: response, reply_markup: self.getTimeButtons(calendar_id, time))
            rescue
            end
            return
        end
        hrs = 20
        min = 0
        matcher = /^([0-9]{2})([0-9]{2})$/.match(time)
        if matcher.nil? then
            @messageSender.process(I18n.t('errors.settime.command_invalid'), chatid)
            return
        end
        if matcher[1].to_i < 0 || matcher[1].to_i > 23 || matcher[2].to_i < 0 || matcher[2].to_i > 59 then
            @messageSender.process(I18n.t('errors.settime.command_invalid'), chatid)
            return
        end
        hrs = matcher[1].to_i
        min = matcher[2].to_i
        subscriber[:notificationtime] = {hrs: hrs, min: min}
        subscriber[:notifiedEvents].clear
        subscriber[:eventlist_id] = calendar_id
        dataStore.updateSubscriber(subscriber)
        reminder_time ="#{pad(subscriber[:notificationtime][:hrs], 2)}:#{pad(subscriber[:notificationtime][:min], 2)}"
        calendar_name = calendars[calendar_id][:description]
        if subscriber[:notificationday] == 0 then
            @messageSender.process(I18n.t('confirmations.setdatetime_success_sameday', reminder_time: reminder_time, calendar_name: calendar_name), chatid)
        elsif subscriber[:notificationday] == 1 then
            @messageSender.process(I18n.t('confirmations.setdatetime_success_precedingday', reminder_time: reminder_time, calendar_name: calendar_name), chatid)
        else
            @messageSender.process(I18n.t('confirmations.setdatetime_success_otherday', reminder_day_count: subscriber[:notificationday], reminder_time: reminder_time, calendar_name: calendar_name), chatid)
        end
    end

    def getCalendarButtons
        calendars = Container::get(:calendars)
        btns = (0..calendars.length - 1).map { |n| [Telegram::Bot::Types::InlineKeyboardButton.new(text: calendars[n][:description], callback_data: "/settime #{n}")] }        
        Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: btns)
    end

    def getTimeButtons(calendar_id, time)
        btns = (1..9).map { |n| Telegram::Bot::Types::InlineKeyboardButton.new(text: "#{n}", callback_data: "/settime #{calendar_id} #{time}#{n}") }
        btns.push(Telegram::Bot::Types::InlineKeyboardButton.new(text: '⌫', callback_data: "/settime #{calendar_id} #{time.chop unless time.nil?}"))
        btns.push(Telegram::Bot::Types::InlineKeyboardButton.new(text: '0️', callback_data: "/settime #{calendar_id} #{time}0"))
        Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: [btns[0..2], btns[3..5], btns[6..8], btns[9..10]])
    end
end
