require 'commands/command'
require 'commands/mixins/EventMessagePusher'
require 'Container'

require 'i18n'

class SubscribeCommand < Command
    include EventMessagePusher

    def initialize(messageSender)
        super(messageSender)
    end

    def process(msg, userid, chatid)
        dataStore = Container::get(:dataStore)
        calendars = Container::get(:calendars)
        command, *args = msg.split(/\s+/)
        if args.length == 0 then
            @messageSender.process(I18n.t('subscribe.choose_calendar'), chatid, self.getCalendarButtons);
            return
        end
        calendar_id = Integer(args[0])
        isSubbed = dataStore.getSubscriberById(userid, calendar_id)
        if (!isSubbed.nil?) then
            @messageSender.process(I18n.t('errors.subscribe.double_subscription'), chatid);
            return
        end
        dataStore.addSubscriber({telegram_id: userid, eventlist_id: calendar_id, notificationday: 1, notificationtime: {hrs: 20, min: 0}, notifiedEvents: []})
        @messageSender.process(I18n.t('confirmations.subscribe_success', calendar_name: calendars[calendar_id][:description]), chatid)
        self.pushEventsDescription(calendar_id, 1, userid, chatid)
    end

    def getCalendarButtons
        calendars = Container::get(:calendars)
        btns = (0..calendars.length - 1).map { |n| [Telegram::Bot::Types::InlineKeyboardButton.new(text: calendars[n][:description], callback_data: "/subscribe #{n}")] }        
        Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: btns)
    end
end
