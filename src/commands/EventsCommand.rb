require 'commands/command'
require 'commands/mixins/EventMessagePusher'
require 'Container'
require 'util'

require 'i18n'

class EventsCommand < Command
    include EventMessagePusher
    def process(msg, userid, chatid, orig)
        command, *args = msg.split(/\s+/)
        calendars = Container::get(:calendars)
        bot = Container::get(:bot)
        calendar_id = args[0]
        count = args[1]
        if calendar_id.nil?
            @messageSender.process(I18n.t('events.choose_calendar'), chatid, self.getCalendarButtons);
            return
        end
        begin
            bot.bot_instance.api.editMessageReplyMarkup(chat_id: orig.message.chat.id, message_id: orig.message.message_id, reply_markup: Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: []))
        rescue
        end
        calendar_id = Integer(calendar_id) rescue -1
        if calendar_id > calendars.length or calendar_id < 0 or calendars[calendar_id].nil? then
            @messageSender.process(I18n.t('errors.events.command_invalid', calendar_id: 0, calendar_name: calendars[0][:description]), chatid)
            return
        end
        if count.nil? then
            count = 5
        end
        count = Integer(count) rescue -1
        if count < 0 then
            @messageSender.process(I18n.t('errors.events.command_invalid', calendar_id: 0, calendar_name: calendars[0][:description]), chatid)
            return
        end
        self.pushEventsDescription(calendar_id, count, userid, chatid)
    end

    def getCalendarButtons
        calendars = Container::get(:calendars)
        btns = (0..calendars.length - 1).map { |n| [Telegram::Bot::Types::InlineKeyboardButton.new(text: calendars[n][:description], callback_data: "/events #{n}")] }        
        Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: btns)
    end
end
