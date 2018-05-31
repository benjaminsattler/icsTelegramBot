require 'commands/command'
require 'util'

require 'i18n'

class SetTimeCommand < Command
  def process(msg, userid, chatid, orig)
    command, *args = msg.split(/\s+/)
    calendars = Container.get(:calendars)
    dataStore = Container.get(:dataStore)
    calendar_id = args[0]
    bot = Container.get(:bot)
    time = args[1]
    if calendar_id.nil?
      @messageSender.process(I18n.t('settime.choose_calendar'), chatid, getCalendarButtons)
      return
    end
    calendar_id = begin
                      Integer(calendar_id)
                    rescue StandardError
                      -1
                    end
    if calendars[calendar_id].nil?
      @messageSender.process(I18n.t('errors.settime.command_invalid', calendar_id: calendars.keys.first, calendar_name: calendars.values.first[:description]), chatid)
      return
    end
    begin
      bot.bot_instance.api.editMessageReplyMarkup(chat_id: orig.message.chat.id, message_id: orig.message.message_id, reply_markup: Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: []))
    rescue StandardError
    end
    subscriber = dataStore.getSubscriberById(userid, calendar_id)
    calendar_name = calendars[calendar_id][:description]
    if subscriber.nil?
      @messageSender.process(I18n.t('errors.no_subscription_teaser', command: '/settime', calendar_name: calendar_name), chatid)
      return
    end
    response = I18n.t('settime.command_inline', response: time)
    if time.nil?
      @messageSender.process(response, chatid, getTimeButtons(calendar_id, time))
      return
    end
    if time.length < 4
      begin
        bot.bot_instance.api.editMessageText(chat_id: orig.message.chat.id, message_id: orig.message.message_id, text: response, reply_markup: getTimeButtons(calendar_id, time))
      rescue StandardError
      end
      return
    end
    hrs = 20
    min = 0
    matcher = /^([0-9]{2})([0-9]{2})$/.match(time)
    if matcher.nil?
      @messageSender.process(I18n.t('errors.settime.command_invalid', calendar_id: calendars.keys.first, calendar_name: calendars.values.first[:description]), chatid)
      return
    end
    if matcher[1].to_i < 0 || matcher[1].to_i > 23 || matcher[2].to_i < 0 || matcher[2].to_i > 59
      @messageSender.process(I18n.t('errors.settime.command_invalid'), chatid)
      return
    end
    hrs = matcher[1].to_i
    min = matcher[2].to_i
    subscriber[:notificationtime] = { hrs: hrs, min: min }
    subscriber[:notifiedEvents].clear
    subscriber[:eventlist_id] = calendar_id
    dataStore.updateSubscriber(subscriber)
    reminder_time = "#{pad(subscriber[:notificationtime][:hrs], 2)}:#{pad(subscriber[:notificationtime][:min], 2)}"
    if subscriber[:notificationday] == 0
      @messageSender.process(I18n.t('confirmations.setdatetime_success_sameday', reminder_time: reminder_time, calendar_name: calendar_name), chatid)
    elsif subscriber[:notificationday] == 1
      @messageSender.process(I18n.t('confirmations.setdatetime_success_precedingday', reminder_time: reminder_time, calendar_name: calendar_name), chatid)
    else
      @messageSender.process(I18n.t('confirmations.setdatetime_success_otherday', reminder_day_count: subscriber[:notificationday], reminder_time: reminder_time, calendar_name: calendar_name), chatid)
    end
  end

  def getCalendarButtons
    calendars = Container.get(:calendars)
    btns = calendars.values.map { |calendar| [Telegram::Bot::Types::InlineKeyboardButton.new(text: calendar[:description], callback_data: "/settime #{calendar[:calendar_id]}")] }
    Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: btns)
  end

  def getTimeButtons(calendar_id, time)
    btns = (1..9).map { |n| Telegram::Bot::Types::InlineKeyboardButton.new(text: n.to_s, callback_data: "/settime #{calendar_id} #{time}#{n}") }
    btns.push(Telegram::Bot::Types::InlineKeyboardButton.new(text: '⌫', callback_data: "/settime #{calendar_id} #{time.chop unless time.nil?}"))
    btns.push(Telegram::Bot::Types::InlineKeyboardButton.new(text: '0️', callback_data: "/settime #{calendar_id} #{time}0"))
    Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: [btns[0..2], btns[3..5], btns[6..8], btns[9..10]])
  end
end
