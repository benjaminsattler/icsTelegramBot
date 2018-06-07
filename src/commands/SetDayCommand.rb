# frozen_string_literal: true

require 'commands/command'
require 'Container'
require 'util'

require 'i18n'

##
# This class represents the /setday command
# given by the user.
class SetDayCommand < Command
  def process(msg, userid, chatid, orig)
    _command, *args = msg.split(/\s+/)
    calendars = Container.get(:calendars)
    data_store = Container.get(:dataStore)
    bot = Container.get(:bot)
    calendar_id = args[0]
    days = args[1]
    if calendar_id.nil?
      @message_sender.process(
        I18n.t(
          'setday.choose_calendar'
        ),
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
          'errors.setday.command_invalid',
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
          command: '/setday',
          calendar_name: calendar_name
        ),
        chatid
      )
      return
    end
    if days.nil?
      @message_sender.process(
        I18n.t('setday.command_inline'),
        chatid,
        days_buttons(calendar_id)
      )
      return
    end
    days = begin
               Integer(days)
             rescue StandardError
               -1
             end
    if days > 14
      @message_sender.process(I18n.t('errors.setday.day_too_early'), chatid)
      return
    end
    if days.negative?
      @message_sender.process(I18n.t('errors.setday.day_in_past'), chatid)
      return
    end

    subscriber[:notificationday] = days
    subscriber[:notifiedEvents].clear
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
      [
        Telegram::Bot::Types::InlineKeyboardButton.new(
          text: calendar[:description],
          callback_data: "/setday #{calendar[:calendar_id]}"
        )
      ]
    end
    Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: btns)
  end

  def days_buttons(calendar_id)
    btns = (0..14).map do |n|
      Telegram::Bot::Types::InlineKeyboardButton.new(
        text: n.to_s,
        callback_data: "/setday #{calendar_id} #{n}"
      )
    end
    Telegram::Bot::Types::InlineKeyboardMarkup.new(
      inline_keyboard: [btns[0..4], btns[5..9], btns[10..14]]
    )
  end
end
