# frozen_string_literal: true

require 'log'
require 'util'
require 'commands'
require 'incoming_message'
require 'message_sender'

require 'date'
require 'telegram/bot'
require 'i18n'
require 'multitrap'

##
# This class represents the telegram bot.
class Bot
  attr_reader :bot_instance, :uptime_start

  @bot_instance = nil
  @token = nil
  @uptime_start = nil
  @admin_users = nil
  @botname = nil

  def initialize(token, admin_users)
    super()
    @token = token
    @admin_users = admin_users
  end

  def run
    @uptime_start = Time.now
    Telegram::Bot::Client.run(@token) do |bot|
      begin
        me = bot.api.getMe
      rescue StandardError => e
        log('Please double check Telegram bot token!')
        raise e
      end
      @bot_instance = bot
      @botname = me['result']['username']
      log("Botname is #{@botname}")
      ping_admin_users(@admin_users)
      until Thread.current[:stop]
        @bot_instance.listen do |message|
          handle_incoming(message)
        end
      end
    end
  end

  def ping_admin_users(users)
    users.each do |user|
      handle_bot_status_message(user, true)
    end
  end

  def handle_subscribe_message(msg, userid, chatid, orig)
    cmd = SubscribeCommand.new(MessageSender.new(@bot_instance))
    cmd.process(msg, userid, chatid, orig)
  end

  def handle_unsubscribe_message(msg, userid, chatid, orig)
    cmd = UnsubscribeCommand.new(MessageSender.new(@bot_instance))
    cmd.process(msg, userid, chatid, orig)
  end

  def handle_my_status_message(msg, userid, chatid)
    cmd = MyStatusCommand.new(MessageSender.new(@bot_instance))
    cmd.process(msg, userid, chatid, false)
  end

  def handle_bot_status_message(chatid, silent = false)
    cmd = BotStatusCommand.new(MessageSender.new(@bot_instance))
    cmd.process(chatid, silent)
  end

  def handle_start_message(msg, userid, chatid)
    cmd = StartCommand.new(MessageSender.new(@bot_instance))
    cmd.process(msg, userid, chatid)
  end

  def handle_help_message(msg, userid, chatid)
    cmd = HelpCommand.new(MessageSender.new(@bot_instance))
    cmd.process(msg, userid, chatid)
  end

  def handle_events_message(msg, userid, chatid, orig)
    cmd = EventsCommand.new(MessageSender.new(@bot_instance))
    cmd.process(msg, userid, chatid, orig)
  end

  def handle_set_day_message(msg, userid, chatid, orig)
    cmd = SetDayCommand.new(MessageSender.new(@bot_instance))
    cmd.process(msg, userid, chatid, orig)
  end

  def handle_set_time_message(msg, userid, chatid, orig)
    cmd = SetTimeCommand.new(MessageSender.new(@bot_instance))
    cmd.process(msg, userid, chatid, orig)
  end

  def notify(calendar_id, event)
    data_store = Container.get(:dataStore)
    calendars = Container.get(:calendars)
    message_sender = MessageSender.new(@bot_instance)
    description = calendars[calendar_id][:description]
    description = I18n.t('event.unknown_calendar') if calendars[calendar_id].nil?
    data_store.all_subscribers.each do |sub|
      next unless !sub[:notifiedEvents].include?(event.id) &&
                  (event.date - Date.today).to_i == sub[:notificationday] &&
                  sub[:notificationtime][:hrs] == Time.new.hour &&
                  sub[:notificationtime][:min] == Time.new.min
      message_sender.process(
        I18n.t(
          'event.reminder',
          summary: event.summary,
          calendar_name: description,
          days_to_event: sub[:notificationday],
          date_of_event: event.date.strftime('%d.%m.%Y')
        ),
        sub[:telegram_id]
      )
      sub[:notifiedEvents].push(event.id)
    end
  end

  def handle_incoming(incoming)
    if incoming.respond_to?('text')
      msg = IncomingMessage.new(
        incoming.text,
        incoming.from,
        incoming.chat,
        incoming
      )
      handle_text_message(msg)
    elsif incoming.respond_to?('data')
      msg = IncomingMessage.new(
        incoming.data,
        incoming.from,
        incoming.message.chat,
        incoming
      )
      begin
        @bot_instance.api.answerCallbackQuery(
          callback_query_id: Integer(incoming.id)
        )
      rescue StandardError
        nil
      end
      handle_text_message(msg)
    end
  end

  def handle_text_message(msg)
    return if msg.nil? || !msg.respond_to?('text') || msg.text.nil?
    command, = msg.text.split(/\s+/)
    command_target = command.include?('@') ? command.split('@')[1] : nil
    case command
    when '/start', "/start@#{@botname}"
      handle_start_message(msg.text, msg.author.id, msg.chat.id)
    when '/subscribe', "/subscribe@#{@botname}"
      handle_subscribe_message(
        msg.text,
        msg.author.id,
        msg.chat.id,
        msg.orig_obj
      )
    when '/setday'
      handle_set_day_message(msg.text, msg.author.id, msg.chat.id, msg.orig_obj)
    when '/settime', "/settime@#{@botname}"
      handle_set_time_message(
        msg.text,
        msg.author.id,
        msg.chat.id,
        msg.orig_obj
      )
    when '/unsubscribe', "/unsubscribe@#{@botname}"
      handle_unsubscribe_message(
        msg.text,
        msg.author.id,
        msg.chat.id,
        msg.orig_obj
      )
    when '/mystatus', "/mystatus@#{@botname}"
      handle_my_status_message(msg.text, msg.author.id, msg.chat.id)
    when '/botstatus', "/botstatus@#{@botname}"
      handle_bot_status_message(msg.chat.id)
    when '/events', "/events@#{@botname}"
      handle_events_message(msg.text, msg.author.id, msg.chat.id, msg.orig_obj)
    when '/help', "/help@#{@botname}"
      handle_help_message(msg.text, msg.author.id, msg.chat.id)
    else
      if command_target.nil?
        MessageSender.new(@bot_instance).process(
          I18n.t('unknown_command'),
          msg.chat.id
        )
      elsif command_target == @botname
        MessageSender.new(@bot_instance).process(
          I18n.t('unknown_command'),
          msg.chat.id
        )
      end
    end
  end
end
