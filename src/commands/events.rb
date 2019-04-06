# frozen_string_literal: true

require 'commands/command'
require 'commands/mixins/event_message_pusher'
require 'container'
require 'messages/message'
require 'util'

require 'i18n'

##
# This class represents the /events command
# given by the user.
class EventsCommand < Command
  include EventMessagePusher
  def process(msg, userid, chatid, orig)
    _command, *args = msg.split(/\s+/)
    calendars = Container.get(:calendars)
    bot = Container.get(:bot)
    calendar_id = args[0]
    count = args[1]
    skip = args[2]
    if calendar_id.nil?
      @message_sender.process(
        Message.new(
          i18nkey: 'events.choose_calendar',
          i18nparams: {},
          id_recv: chatid,
          markup: calendar_buttons
        )
      )
      return
    end
    begin
      bot.bot_instance.edit_message_buttons(
        chat_id: orig.message.chat.id,
        message_id: orig.message.message_id,
        reply_markup: Telegram::Bot::Types::InlineKeyboardMarkup.new(
          inline_keyboard: []
        )
      )
    rescue StandardError
    end
    calendar_id = begin
                    Integer(calendar_id)
                  rescue StandardError
                    -1
                  end
    if calendars[calendar_id].nil?
      @message_sender.process(
        Message.new(
          i18nkey: 'errors.events.command_invalid',
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
    count = 5 if count.nil?
    count = begin
              Integer(count)
            rescue StandardError
              -1
            end
    if count.negative?
      @message_sender.process(
        Message.new(
          i18nkey: 'errors.events.command_invalid',
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
    skip = 0 if skip.nil?
    begin
      skip = Integer(skip)
    rescue StandardError
      skip = -1
    end
    skip = 0 if skip.negative?
    push_events_description(calendar_id, count, userid, chatid, skip)
  end

  def calendar_buttons
    calendars = Container.get(:calendars)
    btns = calendars.values.map do |calendar|
      [
        Telegram::Bot::Types::InlineKeyboardButton.new(
          text: calendar[:description],
          callback_data: "/events #{calendar[:calendar_id]}"
        )
      ]
    end
    Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: btns)
  end
end
