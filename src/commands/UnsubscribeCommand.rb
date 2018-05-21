require 'commands/command'

require 'i18n'

class UnsubscribeCommand < Command
    include EventMessagePusher

    def process(msg, userid, chatid, silent)
        command, *args = msg.split(/\s+/)
        if args.length == 0 then
            @messageSender.process(I18n.t('unsubscribe.choose_calendar'), chatid, self.getCalendarButtons);
            return
        end
        self.dataStore.removeSubscriber({telegram_id: userid, eventlist_id: Integer(args[0])})
        @messageSender.process(I18n.t('confirmations.unsubscribe_success'), chatid)
    end

    def getCalendarButtons
        calendars = Container::get(:calendars)
        btns = (0..calendars.length - 1).map { |n| Telegram::Bot::Types::InlineKeyboardButton.new(text: "Kalendar #{n}", callback_data: "/unsubscribe #{n}") }        
        Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: [btns])
    end
end
