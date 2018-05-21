require 'commands/command'
require 'commands/mixins/EventMessagePusher'
require 'Container'
require 'util'

require 'i18n'

class EventsCommand < Command
    include EventMessagePusher
    def process(msg, userid, chatid)
        command, *args = msg.split(/\s+/)
        calendars = Container::get(:calendars)
        calendar_id = args[0]
        count = args[1]
        if calendar_id.nil?
            @messageSender.process(I18n.t('events.choose_calendar'), chatid, self.getCalendarButtons);
            return
        end
        calendar_id = Integer(calendar_id)
        if calendar_id > calendars.length or calendar_id < 0 or calendars[calendar_id].nil? then
            @messageSender.process(I18n.t('errors.events.command_invalid'), chatid)
            return
        end
        if count.nil? then
            count = 5
        end
        count = Integer(count)
        self.pushEventsDescription(calendar_id, count, userid, chatid)
    end

    def getCalendarButtons
        calendars = Container::get(:calendars)
        btns = (0..calendars.length - 1).map { |n| [Telegram::Bot::Types::InlineKeyboardButton.new(text: calendars[n][:description], callback_data: "/events #{n}")] }        
        Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: btns)
    end
end
