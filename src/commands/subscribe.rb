# frozen_string_literal: true

require 'commands/command'
require 'commands/mixins/event_message_pusher'
require 'container'
require 'messages/message'

require 'i18n'

##
# This class represents a /subscribe command
# given by the user.
class SubscribeCommand < Command
  include EventMessagePusher

  def initialize(message_sender)
    super(message_sender)
  end

  def process(msg, userid, chatid, orig)
    data_store = Container.get(:dataStore)
    calendars = Container.get(:calendars)
    bot = Container.get(:bot)
    _command, *args = msg.split(/\s+/)
    if args.empty?
      @message_sender.process(
        Message.new(
          i18nkey: 'subscribe.choose_calendar',
          i18nparams: {},
          id_recv: chatid,
          markup: calendar_buttons
        )
      )
      return
    end
    begin
      bot.bot_instance.editMessageReplyMarkup(
        chat_id: orig.message.chat.id,
        message_id: orig.message.message_id,
        reply_markup: Telegram::Bot::Types::InlineKeyboardMarkup.new(
          inline_keyboard: []
        )
      )
    rescue StandardError
    end
    calendar_id = begin
                    Integer(args[0])
                  rescue StandardError
                    -1
                  end
    if calendars[calendar_id].nil?
      @message_sender.process(
        Message.new(
          i18nkey: 'errors.subscribe.command_invalid',
          i18nparams: {
            calendar_id: calendars.keys.first,
            calendar_name: calendars.values.first[:description]
          },
          id_recv: chatid,
          markup: nil
        )
      )
      return
    end
    is_subbed = data_store.subscriber_by_id(userid, calendar_id)
    unless is_subbed.nil?
      @message_sender.process(
        Message.new(
          i18nkey: 'errors.subscribe.double_subscription',
          i18nparams: {
            calendar_name: calendars[calendar_id][:description]
          },
          id_recv: chatid,
          markup: nil
        )
      )
      return
    end
    data_store.add_subscriber(
      telegram_id: userid,
      eventlist_id: calendar_id,
      notificationday: 1,
      notificationtime: { hrs: 20, min: 0 },
      notifiedEvents: []
    )
    @message_sender.process(
      Message.new(
        i18nkey: 'confirmations.subscribe_success',
        i18nparams: {
          calendar_name: calendars[calendar_id][:description]
        },
        id_recv: chatid,
        markup: nil
      )
    )
    push_events_description(calendar_id, 1, userid, chatid)
  end

  def calendar_buttons
    calendars = Container.get(:calendars)
    btns = calendars.values.map do |calendar|
      [
        Telegram::Bot::Types::InlineKeyboardButton.new(
          text: calendar[:description],
          callback_data: "/subscribe #{calendar[:calendar_id]}"
        )
      ]
    end
    Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: btns)
  end
end
