require 'commands/command'
require 'commands/mixins/EventMessagePusher'
require 'Container'

require 'i18n'

class SubscribeCommand < Command
  include EventMessagePusher

  def initialize(messageSender)
    super(messageSender)
  end

  def process(msg, userid, chatid, orig)
    dataStore = Container.get(:dataStore)
    calendars = Container.get(:calendars)
    bot = Container.get(:bot)
    command, *args = msg.split(/\s+/)
    if args.empty?
      @messageSender.process(I18n.t('subscribe.choose_calendar'), chatid, getCalendarButtons)
      return
    end
    begin
      bot.bot_instance.api.editMessageReplyMarkup(chat_id: orig.message.chat.id, message_id: orig.message.message_id, reply_markup: Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: []))
    rescue StandardError
    end
    calendar_id = begin
                    Integer(args[0])
                  rescue StandardError
                    -1
                  end
    if calendars[calendar_id].nil?
      @messageSender.process(I18n.t('errors.subscribe.command_invalid', calendar_id: calendars.keys.first, calendar_name: calendars.values.first[:description]), chatid)
      return
    end
    isSubbed = dataStore.getSubscriberById(userid, calendar_id)
    unless isSubbed.nil?
      @messageSender.process(I18n.t('errors.subscribe.double_subscription', calendar_name: calendars[calendar_id][:description]), chatid)
      return
    end
    dataStore.addSubscriber(telegram_id: userid, eventlist_id: calendar_id, notificationday: 1, notificationtime: { hrs: 20, min: 0 }, notifiedEvents: [])
    @messageSender.process(I18n.t('confirmations.subscribe_success', calendar_name: calendars[calendar_id][:description]), chatid)
    pushEventsDescription(calendar_id, 1, userid, chatid)
  end

  def getCalendarButtons
    calendars = Container.get(:calendars)
    btns = calendars.values.map { |calendar| [Telegram::Bot::Types::InlineKeyboardButton.new(text: calendar[:description], callback_data: "/subscribe #{calendar[:calendar_id]}")] }
    Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: btns)
  end
end
