require 'commands/command'

require 'i18n'

class UnsubscribeCommand < Command
    include EventMessagePusher

    def process(msg, userid, chatid)
        command, *args = msg.split(/\s+/)
        calendars = Container::get(:calendars)
        if args.length == 0 then
            @messageSender.process(I18n.t('unsubscribe.choose_calendar'), chatid, self.getCalendarButtons);
            return
        end
        calendar_id = Integer(args[0])
        Container::get(:dataStore).removeSubscriber({telegram_id: userid, eventlist_id: calendar_id})
        @messageSender.process(I18n.t('confirmations.unsubscribe_success', calendar_name: calendars[calendar_id][:description]), chatid)
    end

    def getCalendarButtons
        calendars = Container::get(:calendars)
        btns = (0..calendars.length - 1).map { |n| [Telegram::Bot::Types::InlineKeyboardButton.new(text: calendars[n][:description], callback_data: "/unsubscribe #{n}")] }        
        Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: btns)
    end
end
