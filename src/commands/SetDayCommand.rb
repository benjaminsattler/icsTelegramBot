require 'commands/command'
require 'Container'
require 'util'

require 'i18n'

class SetDayCommand < Command
    def process(msg, userid, chatid, orig)
        command, *args = msg.split(/\s+/)
        calendars = Container::get(:calendars)
        dataStore = Container::get(:dataStore)
        bot = Container::get(:bot)
        calendar_id = args[0]
        days = args[1]
        if calendar_id.nil?
            @messageSender.process(I18n.t('events.choose_calendar'), chatid, self.getCalendarButtons)
            return
        end
        calendar_id = Integer(calendar_id) rescue -1
        if calendars[calendar_id].nil? then
            @messageSender.process(I18n.t('errors.setday.command_invalid', calendar_id: calendars.keys.first, calendar_name: calendars.values.first[:description]), chatid)
            return
        end
        begin
            bot.bot_instance.api.editMessageReplyMarkup(chat_id: orig.message.chat.id, message_id: orig.message.message_id, reply_markup: Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: []))
        rescue
        end
        subscriber = dataStore.getSubscriberById(userid, calendar_id)
        calendar_name = calendars[calendar_id][:description]
        if subscriber.nil? then
            @messageSender.process(I18n.t('errors.no_subscription_teaser', command: '/setday', calendar_name: calendar_name), chatid)
            return
        end
        if days.nil?
            @messageSender.process(I18n.t('setday.command_inline'), chatid, self.getDaysButtons(calendar_id))
            return
        end
        days = Integer(days) rescue -1
        if days > 14 then
            @messageSender.process(I18n.t('errors.setday.day_too_early'), chatid)
            return
        end
        if days < 0 then
            @messageSender.process(I18n.t('errors.setday.day_in_past'), chatid)
            return
        end

        subscriber[:notificationday] = days
        subscriber[:notifiedEvents].clear
        dataStore.updateSubscriber(subscriber)
        reminder_time = "#{pad(subscriber[:notificationtime][:hrs], 2)}:#{pad(subscriber[:notificationtime][:min], 2)}"
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
        btns = calendars.values.map { |calendar| [Telegram::Bot::Types::InlineKeyboardButton.new(text: calendar[:description], callback_data: "/setday #{calendar[:calendar_id]}")] }        
        Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: btns)
    end

    def getDaysButtons(calendar_id)
        btns = (0..14).map { |n| Telegram::Bot::Types::InlineKeyboardButton.new(text: "#{n}", callback_data: "/setday #{calendar_id} #{n}") }        
        Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: [btns[0..4], btns[5..9], btns[10..14]])
    end
end
