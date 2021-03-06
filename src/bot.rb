# frozen_string_literal: true

require 'log'
require 'util'
require 'commands'
require 'incoming_message'
require 'message_sender'
require 'message_log'
require 'events/calendar'
require 'events/event'
require 'file_writer'
require 'https_file_downloader'
require 'statistics'
require 'sys_info'
require 'file_uploader'
require 'messages/message'
require 'messages/notification'

require 'date'
require 'telegram/bot'
require 'i18n'
require 'multitrap'

##
# This class represents the telegram bot.
class Bot
  attr_reader :bot_instance, :statistics, :token

  @bot_instance = nil
  @token = nil
  @statistics = nil
  @admin_users = nil
  @botname = nil

  def initialize(token, admin_users, statistics, message_log)
    @token = token.chomp
    @admin_users = admin_users
    @statistics = statistics
    @message_log = message_log
  end

  def run(api)
    api.run(@token) do |bot|
      begin
        me = bot.get_identity
      rescue StandardError => e
        log('Please double check Telegram bot token!')
        raise e
      end
      @bot_instance = bot
      @botname = me['result']['username']
      log("Botname is #{@botname}")
      ping_admin_users(@admin_users)
      until Thread.current[:stop]
        bot.listen do |message|
          handle_incoming(message)
        end
      end
    end
  end

  def ping_admin_users(users)
    message_sender = MessageSender.new(
      self,
      @bot_instance,
      @statistics,
      @message_log
    )
    start_time = @statistics.get[:starttime].strftime('%d.%m.%Y %H:%M:%S')
    users.each do |user|
      message_sender.process(
        Message.new(
          i18nkey: 'ping',
          i18nparams: {
            start_time: start_time,
            version: SysInfo.new.docker_info[:image_version]
          },
          id_recv: user,
          markup: nil
        )
      )
    end
  end

  def handle_subscribe_message(msg, userid, chatid, orig)
    cmd = SubscribeCommand.new(
      MessageSender.new(
        self,
        @bot_instance,
        @statistics,
        @message_log
      )
    )
    cmd.process(msg, userid, chatid, orig)
  end

  def handle_unsubscribe_message(msg, userid, chatid, orig)
    cmd = UnsubscribeCommand.new(
      MessageSender.new(
        self,
        @bot_instance,
        @statistics,
        @message_log
      )
    )
    cmd.process(msg, userid, chatid, orig)
  end

  def handle_my_status_message(msg, userid, chatid)
    cmd = MyStatusCommand.new(
      MessageSender.new(
        self,
        @bot_instance,
        @statistics,
        @message_log
      )
    )
    cmd.process(msg, userid, chatid, false)
  end

  def handle_bot_status_message(msg, userid, chatid)
    cmd = AdminCommand.new(
      self,
      BotStatusCommand.new(
        MessageSender.new(
          self,
          @bot_instance,
          @statistics,
          @message_log
        ),
        SysInfo.new
      )
    )
    cmd.process(msg, userid, chatid)
  end

  def handle_start_message(msg, userid, chatid)
    cmd = StartCommand.new(
      MessageSender.new(
        self,
        @bot_instance,
        @statistics,
        @message_log
      )
    )
    cmd.process(msg, userid, chatid)
  end

  def handle_help_message(msg, userid, chatid)
    cmd = HelpCommand.new(
      MessageSender.new(
        self,
        @bot_instance,
        @statistics,
        @message_log
      )
    )
    cmd.process(msg, userid, chatid)
  end

  def handle_events_message(msg, userid, chatid, orig)
    cmd = EventsCommand.new(
      MessageSender.new(
        self,
        @bot_instance,
        @statistics,
        @message_log
      )
    )
    cmd.process(msg, userid, chatid, orig)
  end

  def handle_set_day_message(msg, userid, chatid, orig)
    cmd = SetDayCommand.new(
      MessageSender.new(
        self,
        @bot_instance,
        @statistics,
        @message_log
      )
    )
    cmd.process(msg, userid, chatid, orig)
  end

  def handle_set_time_message(msg, userid, chatid, orig)
    cmd = SetTimeCommand.new(
      MessageSender.new(
        self,
        @bot_instance,
        @statistics,
        @message_log
      ),
      @bot_instance
    )
    cmd.process(msg, userid, chatid, orig)
  end

  def handle_document_upload(msg, userid, chatid, orig)
    cmd = AdminCommand.new(
      self,
      UploadCommand.new(
        MessageSender.new(
          self,
          @bot_instance,
          @statistics,
          @message_log
        ),
        HttpsFileDownloader.new,
        FileWriter.new,
        ICS::FileParser
      )
    )
    cmd.process(msg, userid, chatid, orig)
  end

  def handle_broadcast_message(msg, userid, chatid)
    message_sender = MessageSender.new(
      self,
      @bot_instance,
      @statistics,
      @message_log
    )
    cmd = AdminCommand.new(
      self,
      BroadcastCommand.new(
        message_sender
      )
    )
    cmd.process(msg, userid, chatid, false)
  end

  def handle_download_message(msg, userid, chatid)
    message_sender = MessageSender.new(
      self,
      @bot_instance,
      @statistics,
      @message_log
    )
    cmd = AdminCommand.new(
      self,
      DownloadCommand.new(
        message_sender,
        FileUploader.new
      )
    )
    cmd.process(msg, userid, chatid, false)
  end

  def notify(calendar_id, event)
    data_store = Container.get(:dataStore)
    calendars = Container.get(:calendars)
    message_sender = MessageSender.new(
      self,
      @bot_instance,
      @statistics,
      @message_log
    )
    subs = data_store.all_subscribers(calendar_id)

    subs.reject! do |sub|
      data_store.notification?(
        sub,
        calendars[calendar_id],
        event
      )
    end

    subs.select! do |sub|
      daydiff = (event.date - Date.today).to_i
      daydiff == sub[:notificationday] &&
        sub[:notificationtime][:hrs] == Time.new.hour &&
        sub[:notificationtime][:min] == Time.new.min
    end

    subs.each do |sub|
      @statistics.sent_reminder
      message_sender.process(
        Notification.new(
          recv: sub,
          event: event,
          calendar: calendars[calendar_id],
          message_sender: message_sender,
          persistence: data_store
        )
      )
    end
  end

  def handle_incoming(incoming)
    @statistics.recv_msg
    if incoming.respond_to?('document') && incoming.document.present?
      msg = IncomingMessage.new(
        incoming.document.file_id,
        incoming.from,
        incoming.chat,
        incoming
      )
      handle_document_upload(msg.text, msg.author.id, msg.chat.id, msg.orig_obj)
    elsif incoming.respond_to?('text')
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
    command.downcase!
    command_target = command.include?('@') ? command.split('@')[1] : nil
    case command
    when '/start', "/start@#{@botname.downcase}"
      handle_start_message(msg.text, msg.author.id, msg.chat.id)
    when '/subscribe', "/subscribe@#{@botname.downcase}"
      handle_subscribe_message(
        msg.text,
        msg.author.id,
        msg.chat.id,
        msg.orig_obj
      )
    when '/setday', "/setday@#{@botname.downcase}"
      handle_set_day_message(msg.text, msg.author.id, msg.chat.id, msg.orig_obj)
    when '/settime', "/settime@#{@botname.downcase}"
      handle_set_time_message(
        msg.text,
        msg.author.id,
        msg.chat.id,
        msg.orig_obj
      )
    when '/unsubscribe', "/unsubscribe@#{@botname.downcase}"
      handle_unsubscribe_message(
        msg.text,
        msg.author.id,
        msg.chat.id,
        msg.orig_obj
      )
    when '/mystatus', "/mystatus@#{@botname.downcase}"
      handle_my_status_message(msg.text, msg.author.id, msg.chat.id)
    when '/botstatus', "/botstatus@#{@botname.downcase}"
      handle_bot_status_message(msg.text, msg.author.id, msg.chat.id)
    when '/events', "/events@#{@botname.downcase}"
      handle_events_message(msg.text, msg.author.id, msg.chat.id, msg.orig_obj)
    when '/broadcast', "/broadcast@#{@botname.downcase}"
      handle_broadcast_message(msg.text, msg.author.id, msg.chat.id)
    when '/help', "/help@#{@botname.downcase}"
      handle_help_message(msg.text, msg.author.id, msg.chat.id)
    when '/download', "/download@#{@botname.downcase}"
      handle_download_message(msg.text, msg.author.id, msg.chat.id)
    else
      message_sender = MessageSender.new(
        self,
        @bot_instance,
        @statistics,
        @message_log
      )
      if command_target.nil?
        message_sender.process(
          Message.new(
            i18nkey: 'unknown_command',
            i18nparams: {},
            id_recv: msg.chat.id,
            markup: nil
          )
        )
      elsif command_target.casecmp(@botname)
        message_sender.process(
          Message.new(
            i18nkey: 'unknown_command',
            i18nparams: {},
            id_recv: msg.chat.id,
            markup: nil
          )
        )
      end
    end
  end

  def get_file(file_id)
    @bot_instance.get_file(file_id: file_id)
  end

  def admin_user?(user_id)
    @admin_users.include?(user_id.to_s)
  end
end
