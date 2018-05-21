require 'commands/command'
require 'commands/mixins/EventMessagePusher'
require 'Container'

require 'i18n'

class SubscribeCommand < Command
    include EventMessagePusher

    def initialize(messageSender)
        super(messageSender)
    end

    def process(msg, userid, chatid, silent)
        isSubbed = self.dataStore.getSubscriberById(userid)
        if (!isSubbed.nil?) then
            self.bot.pushMessage(I18n.t('errors.subscribe.double_subscription'), chatid);
            return
        end
        command, *args = msg.split(/\s+/)
        if args.length == 0 then
            @messageSender.process(I18n.t('subscribe.choose_calendar'), chatid, self.getCalendarButtons);
            return
        end
        self.dataStore.addSubscriber({telegram_id: userid, eventlist_id: args[0], notificationday: 1, notificationtime: {hrs: 20, min: 0}, notifiedEvents: []})
        @messageSender.process(I18n.t('confirmations.subscribe_success'), chatid)
        #self.pushEventsDescription(self.calendars[1].getEvents(args[1]), userid, chatid)
    end

    def getCalendarButtons
        calendars = Container::get(:calendars)
        btns = (0..calendars.length - 1).map { |n| Telegram::Bot::Types::InlineKeyboardButton.new(text: "Kalendar #{n}", callback_data: "/subscribe #{n}") }        
        Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: [btns])
    end
end
