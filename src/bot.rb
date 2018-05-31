require 'log'
require 'util'
require 'commands'
require 'IncomingMessage'
require 'MessageSender'

require 'telegram/bot'
require 'i18n'
require 'multitrap'

class Bot
  attr_reader :bot_instance, :uptime_start

  @bot_instance = nil
  @token = nil
  @uptime_start = nil
  @adminUsers = nil
  @botname = nil

  def initialize(token, adminUsers)
    super()
    @token = token
    @adminUsers = adminUsers
  end

  def run
    @uptime_start = DateTime.now
    Telegram::Bot::Client.run(@token) do |bot|
      begin
        me = bot.api.getMe
      rescue Exception => e
        log('Please double check Telegram bot token!')
        raise e
      end
      @bot_instance = bot
      @botname = me['result']['username']
      log("Botname is #{@botname}")
      pingAdminUsers(@adminUsers)
      until Thread.current[:stop]
        @bot_instance.listen do |message|
          handleIncoming(message)
        end
      end
    end
  end

  def pingAdminUsers(users)
    users.each do |user|
      handleBotStatusMessage(user, true)
    end
  end

  def handleSubscribeMessage(msg, userid, chatid, orig)
    cmd = SubscribeCommand.new(MessageSender.new(@bot_instance))
    cmd.process(msg, userid, chatid, orig)
  end

  def handleUnsubscribeMessage(msg, userid, chatid, orig)
    cmd = UnsubscribeCommand.new(MessageSender.new(@bot_instance))
    cmd.process(msg, userid, chatid, orig)
  end

  def handleMyStatusMessage(msg, userid, chatid)
    cmd = MyStatusCommand.new(MessageSender.new(@bot_instance))
    cmd.process(msg, userid, chatid, false)
  end

  def handleBotStatusMessage(chatid, silent = false)
    cmd = BotStatusCommand.new(MessageSender.new(@bot_instance))
    cmd.process(chatid, silent)
  end

  def handleStartMessage(msg, userid, chatid)
    cmd = StartCommand.new(MessageSender.new(@bot_instance))
    cmd.process(msg, userid, chatid)
  end

  def handleHelpMessage(msg, userid, chatid)
    cmd = HelpCommand.new(MessageSender.new(@bot_instance))
    cmd.process(msg, userid, chatid)
  end

  def handleEventsMessage(msg, userid, chatid, orig)
    cmd = EventsCommand.new(MessageSender.new(@bot_instance))
    cmd.process(msg, userid, chatid, orig)
  end

  def handleSetDayMessage(msg, userid, chatid, orig)
    cmd = SetDayCommand.new(MessageSender.new(@bot_instance))
    cmd.process(msg, userid, chatid, orig)
  end

  def handleSetTimeMessage(msg, userid, chatid, orig)
    cmd = SetTimeCommand.new(MessageSender.new(@bot_instance))
    cmd.process(msg, userid, chatid, orig)
  end

  def notify(_calendar_id, event)
    dataStore = Container.get(:dataStore)
    messageSender = MessageSender.new(@bot_instance)
    dataStore.getAllSubscribers.each do |subscriber|
      if !subscriber[:notifiedEvents].include?(event.id) && (event.date - Date.today).to_i == subscriber[:notificationday] && subscriber[:notificationtime][:hrs] == Time.new.hour && subscriber[:notificationtime][:min] == Time.new.min
        messageSender.process(I18n.t('event.reminder', summary: event.summary, days_to_event: subscriber[:notificationday], date_of_event: event.date.strftime('%d.%m.%Y')), subscriber[:telegram_id])
        subscriber[:notifiedEvents].push(event.id)
      end
    end
  end

  def handleIncoming(incoming)
    if incoming.respond_to?('text')
      msg = IncomingMessage.new(incoming.text, incoming.from, incoming.chat, incoming)
      handleTextMessage(msg)
    elsif incoming.respond_to?('data')
      msg = IncomingMessage.new(incoming.data, incoming.from, incoming.message.chat, incoming)
      # @bot_instance.api.editMessageReplyMarkup(message_id: incoming.message.message_id, chat_id: incoming.message.chat.id, reply_markup: Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: []))
      begin
         @bot_instance.api.answerCallbackQuery(callback_query_id: Integer(incoming.id))
       rescue StandardError
         nil
       end
      handleTextMessage(msg)
    end
  end

  def handleTextMessage(msg)
    return if msg.nil? || !msg.respond_to?('text') || msg.text.nil?
    command, = msg.text.split(/\s+/)
    commandTarget = command.include?('@') ? command.split('@')[1] : nil
    case command
    when '/start', "/start@#{@botname}"
      handleStartMessage(msg.text, msg.author.id, msg.chat.id)
    when '/subscribe', "/subscribe@#{@botname}"
      handleSubscribeMessage(msg.text, msg.author.id, msg.chat.id, msg.origObj)
    when '/setday'
      handleSetDayMessage(msg.text, msg.author.id, msg.chat.id, msg.origObj)
    when '/settime', "/settime@#{@botname}"
      handleSetTimeMessage(msg.text, msg.author.id, msg.chat.id, msg.origObj)
    when '/unsubscribe', "/unsubscribe@#{@botname}"
      handleUnsubscribeMessage(msg.text, msg.author.id, msg.chat.id, msg.origObj)
    when '/mystatus', "/mystatus@#{@botname}"
      handleMyStatusMessage(msg.text, msg.author.id, msg.chat.id)
    when '/botstatus', "/botstatus@#{@botname}"
      handleBotStatusMessage(msg.chat.id)
    when '/events', "/events@#{@botname}"
      handleEventsMessage(msg.text, msg.author.id, msg.chat.id, msg.origObj)
    when '/help', "/help@#{@botname}"
      handleHelpMessage(msg.text, msg.author.id, msg.chat.id)
    else
      if commandTarget == @botname
        MessageSender.new(@bot_instance).process(I18n.t('unknown_command'), msg.chat.id)
      end
    end
  end
end
