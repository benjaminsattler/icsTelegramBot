require 'commands/command'

require 'i18n'

class UnsubscribeCommand < Command
    include EventMessagePusher

    def process(msg, userid, chatid, orig)
        command, *args = msg.split(/\s+/)
        calendars = Container::get(:calendars)
        bot = Container::get(:bot)
        if args.length == 0 then
            @messageSender.process(I18n.t('unsubscribe.choose_calendar'), chatid, self.getCalendarButtons);
            return
        end
        begin
            bot.bot_instance.api.editMessageReplyMarkup(chat_id: orig.message.chat.id, message_id: orig.message.message_id, reply_markup: Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: []))
        rescue
        end
        calendar_id = Integer(args[0]) rescue -1
        if calendars[calendar_id].nil? then
            @messageSender.process(I18n.t('errors.unsubscribe.command_invalid', calendar_id: calendars.keys.first, calendar_name: calendars.values.first[:description]), chatid)
            return
        end
        Container::get(:dataStore).removeSubscriber({telegram_id: userid, eventlist_id: calendar_id})
        @messageSender.process(I18n.t('confirmations.unsubscribe_success', calendar_name: calendars[calendar_id][:description]), chatid)
    end

    def getCalendarButtons
        calendars = Container::get(:calendars)
        btns = calendars.values.map { |calendar| [Telegram::Bot::Types::InlineKeyboardButton.new(text: calendar[:description], callback_data: "/unsubscribe #{calendar[:calendar_id]}")] }        
        Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: btns)
    end
end
