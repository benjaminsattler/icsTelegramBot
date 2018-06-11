# frozen_string_literal: true

require 'commands/command'
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
        I18n.t('settime.choose_calendar'),
        chatid,
        calendar_buttons
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
        I18n.t(
          'errors.settime.command_invalid',
          calendar_id: calendars.keys.first,
          calendar_name: calendars.values.first[:description]
        ),
        chatid
      )
      return
    end
    begin
      bot.bot_instance.api.editMessageReplyMarkup(
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
        I18n.t(
          'errors.no_subscription_teaser',
          command: '/settime',
          calendar_name: calendar_name
        ),
        chatid
      )
      return
    end
    response = I18n.t('settime.command_inline', response: time)
    if time.nil?
      @message_sender.process(response, chatid, time_buttons(calendar_id, time))
      return
    end
    if time.length < 4
      begin
        bot.bot_instance.api.editMessageText(
          chat_id: orig.message.chat.id,
          message_id: orig.message.message_id,
          text: response,
          reply_markup: time_buttons(calendar_id, time)
        )
      rescue StandardError
      end
      return
    end
    matcher = /^([0-9]{2})([0-9]{2})$/.match(time)
    if matcher.nil?
      @message_sender.process(
        I18n.t(
          'errors.settime.command_invalid',
          calendar_id: calendars.keys.first,
          calendar_name: calendars.values.first[:description]
        ),
        chatid
      )
      return
    end
    if matcher[1].to_i.negative? || matcher[1].to_i > 23 ||
       matcher[2].to_i.negative? || matcher[2].to_i > 59
      @message_sender.process(
        I18n.t(
          'errors.settime.command_invalid',
          calendar_id: calendars.keys.first,
          calendar_name: calendars.values.first[:description]
        ),
        chatid
      )
      return
    end
    hrs = matcher[1].to_i
    min = matcher[2].to_i
    subscriber[:notificationtime] = { hrs: hrs, min: min }
    subscriber[:notifiedEvents].clear
    subscriber[:eventlist_id] = calendar_id
    data_store.update_subscriber(subscriber)
    reminder_time = "#{Util.pad(subscriber[:notificationtime][:hrs], 2)}"\
                    ":#{Util.pad(subscriber[:notificationtime][:min], 2)}"
    if subscriber[:notificationday].zero?
      @message_sender.process(
        I18n.t(
          'confirmations.setdatetime_success_sameday',
          reminder_time: reminder_time,
          calendar_name: calendar_name
        ),
        chatid
      )
    elsif subscriber[:notificationday] == 1
      @message_sender.process(
        I18n.t(
          'confirmations.setdatetime_success_precedingday',
          reminder_time: reminder_time,
          calendar_name: calendar_name
        ),
        chatid
      )
    else
      @message_sender.process(
        I18n.t(
          'confirmations.setdatetime_success_otherday',
          reminder_day_count: subscriber[:notificationday],
          reminder_time: reminder_time,
          calendar_name: calendar_name
        ),
        chatid
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
