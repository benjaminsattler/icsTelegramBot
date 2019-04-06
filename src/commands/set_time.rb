# frozen_string_literal: true

require 'commands/command'
require 'messages/message'
require 'util'

require 'i18n'

##
# This class represents a /settime command
# given by the user.
class SetTimeCommand < Command
  def process(msg, userid, chatid, orig)
    _command, *args = msg.split(/\s+/)
    calendars = Container.get(:calendars)
    data_store = Container.get(:dataStore)
    calendar_id = args[0]
    bot = Container.get(:bot)
    time = args[1]
    if calendar_id.nil?
      @message_sender.process(
        Message.new(
          i18nkey: 'settime.choose_calendar',
          i18nparams: {},
          id_recv: chatid,
          markup: calendar_buttons
        )
      )
      return
    end
    calendar_id = begin
                    Integer(calendar_id)
                  rescue StandardError
                    -1
                  end
    if calendars[calendar_id].nil?
      @message_sender.process(
        Message.new(
          i18nkey: 'errors.settime.command_invalid',
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
    subscriber = data_store.subscriber_by_id(userid, calendar_id)
    calendar_name = calendars[calendar_id][:description]
    if subscriber.nil?
      @message_sender.process(
        Message.new(
          i18nkey: 'errors.no_subscription_teaser',
          i18nparams: {
            command: '/settime',
            calendar_name: calendar_name
          },
          id_recv: chatid,
          markup: nil
        )
      )
      return
    end
    if time.nil?
      @message_sender.process(
        Message.new(
          i18nkey: 'settime.command_inline',
          i18nparams: {
            response: time
          },
          id_recv: chatid,
          markup: time_buttons(calendar_id, time)
        )
      )
      return
    end
    if time.length < 4
      begin
        bot.bot_instance.edit_message_text(
          chat_id: orig.message.chat.id,
          message_id: orig.message.message_id,
          text: I18n.t('settime.command_inline', response: time),
          reply_markup: time_buttons(calendar_id, time)
        )
      rescue StandardError
      end
      return
    end
    matcher = /^([0-9]{2})([0-9]{2})$/.match(time)
    if matcher.nil?
      @message_sender.process(
        Message.new(
          i18nkey: 'errors.settime.command_invalid',
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
    if matcher[1].to_i.negative? || matcher[1].to_i > 23 ||
       matcher[2].to_i.negative? || matcher[2].to_i > 59
      @message_sender.process(
        Message.new(
          i18nkey: 'errors.settime.command_invalid',
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
    hrs = matcher[1].to_i
    min = matcher[2].to_i
    time = hrs * 100
    time += min
    subscriber[:notifiedEvents].clear
    data_store.update_time(subscriber[:telegram_id], calendar_id, time)
    reminder_time = "#{Util.pad(hrs, 2)}"\
                    ":#{Util.pad(min, 2)}"
    if subscriber[:notificationday].zero?
      @message_sender.process(
        Message.new(
          i18nkey: 'confirmations.setdatetime_success_sameday',
          i18nparams: {
            reminder_time: reminder_time,
            calendar_name: calendar_name
          },
          id_recv: chatid,
          markup: nil
        )
      )
    elsif subscriber[:notificationday] == 1
      @message_sender.process(
        Message.new(
          i18nkey: 'confirmations.setdatetime_success_precedingday',
          i18nparams: {
            reminder_time: reminder_time,
            calendar_name: calendar_name
          },
          id_recv: chatid,
          markup: nil
        )
      )
    else
      @message_sender.process(
        Message.new(
          i18nkey: 'confirmations.setdatetime_success_otherday',
          i18nparams: {
            reminder_day_count: subscriber[:notificationday],
            reminder_time: reminder_time,
            calendar_name: calendar_name
          },
          id_recv: chatid,
          markup: nil
        )
      )
    end
  end

  def calendar_buttons
    calendars = Container.get(:calendars)
    btns = calendars.values.map do |calendar|
      [Telegram::Bot::Types::InlineKeyboardButton.new(
        text: calendar[:description],
        callback_data: "/settime #{calendar[:calendar_id]}"
      )]
    end
    Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: btns)
  end

  def time_buttons(calendar_id, time)
    btns = (1..9).map do |n|
      Telegram::Bot::Types::InlineKeyboardButton.new(
        text: n.to_s,
        callback_data: "/settime #{calendar_id} #{time}#{n}"
      )
    end
    btns.push(
      Telegram::Bot::Types::InlineKeyboardButton.new(
        text: '⌫',
        callback_data: "/settime #{calendar_id} #{time.chop unless time.nil?}"
      )
    )
    btns.push(
      Telegram::Bot::Types::InlineKeyboardButton.new(
        text: '0️',
        callback_data: "/settime #{calendar_id} #{time}0"
      )
    )
    Telegram::Bot::Types::InlineKeyboardMarkup.new(
      inline_keyboard: [
        btns[0..2],
        btns[3..5],
        btns[6..8],
        btns[9..10]
      ]
    )
  end
end
