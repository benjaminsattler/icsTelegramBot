require 'log'
require 'query/SetTimeQuery'
require 'query/SetDayQuery'
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
                me = bot.api.getMe()
            rescue Exception => e
                log("Please double check Telegram bot token!")
                raise e
            end
            @bot_instance = bot
            @botname = me['result']['username']
            log("Botname is #{@botname}")
            #self.pingAdminUsers(@adminUsers)
            while not Thread.current[:stop]
                @bot_instance.listen do |message| 
                    self.handleIncoming(message)
                end
            end
        end
    end

    def handleSubscribeMessage(msg, userid, chatid)
        cmd = SubscribeCommand.new(MessageSender.new(@bot_instance))
        cmd.process(msg, userid, chatid)
    end

    def handleUnsubscribeMessage(msg, userid, chatid)
        cmd = UnsubscribeCommand.new(MessageSender.new(@bot_instance))
        cmd.process(msg, userid, chatid)
    end

    def handleMyStatusMessage(msg, userid, chatid)
        cmd = MyStatusCommand.new(MessageSender.new(@bot_instance))
        cmd.process(msg, userid, chatid, false)
    end

    def handleBotStatusMessage(msg, userid, chatid)
        cmd = BotStatusCommand.new(MessageSender.new(@bot_instance))
        cmd.process(msg, userid, chatid)
    end

    def handleStartMessage(msg, userid, chatid)
        cmd = StartCommand.new(MessageSender.new(@bot_instance))
        cmd.process(msg, userid, chatid)
    end

    def handleHelpMessage(msg, userid, chatid)
        cmd = HelpCommand.new(MessageSender.new(@bot_instance))
        cmd.process(msg, userid, chatid)
    end

    def handleEventsMessage(msg, userid, chatid)
        cmd = EventsCommand.new(MessageSender.new(@bot_instance))
        cmd.process(msg, userid, chatid)
    end

    def handleSetDayMessage(msg, userid, chatid)
        cmd = SetDayCommand.new(MessageSender.new(@bot_instance))
        cmd.process(msg, userid, chatid)
    end
    
    def notify(event)
        Container::get(:calendars).each do |calendar|
            calendar.getAllSubscribers.each do |subscriber|
                if !subscriber[:notifiedEvents].include?(event.id) && (event.date - Date.today()).to_i == subscriber[:notificationday] && subscriber[:notificationtime][:hrs] == Time.new.hour && subscriber[:notificationtime][:min] == Time.new.min then
                    self.pushMessage(I18n.t('event.reminder', summary: event.summary, days_to_event: subscriber[:notificationday], date_of_event: event.date.strftime('%d.%m.%Y')), subscriber[:telegram_id])
                    subscriber[:notifiedEvents].push(event.id)
                end
            end
        end
    end

    def handleIncoming(incoming)
        if incoming.respond_to?('text') then
            msg = IncomingMessage.new(incoming.text, incoming.from, incoming.chat);
            self.handleTextMessage(msg)
        elsif incoming.respond_to?('data') then
            msg = IncomingMessage.new(incoming.data, incoming.from, incoming.message.chat);
           # @bot_instance.api.editMessageReplyMarkup(message_id: incoming.message.message_id, chat_id: incoming.message.chat.id, reply_markup: Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: []))
            @bot_instance.api.answerCallbackQuery(callback_query_id: Integer(incoming.id))
            self.handleTextMessage(msg)
        end
    end
    
    def handleTextMessage(msg)
        if msg.nil? or !msg.respond_to?('text') then
            return
        end
        command, *args = msg.text.split(/\s+/)
        commandTarget = command.include?('@') ? command.split('@')[1] : nil
        case command
        when '/start', "/start@#{@botname}"
            self.handleStartMessage(msg.text, msg.author.id, msg.chat.id)
        when '/subscribe', "/subscribe@#{@botname}"
            self.handleSubscribeMessage(msg.text, msg.author.id, msg.chat.id)
        when '/setday'
            self.handleSetDayMessage(msg.text, msg.author.id, msg.chat.id)
        when '/settime', "/settime@#{@botname}"
            #self.handleSetTimeMessage(msg.text, msg.from.id, msg.chat.id)
        when '/unsubscribe', "/unsubscribe@#{@botname}"
            self.handleUnsubscribeMessage(msg.text, msg.author.id, msg.chat.id)
        when '/mystatus', "/mystatus@#{@botname}"
            self.handleMyStatusMessage(msg.text, msg.author.id, msg.chat.id)
        when '/botstatus', "/botstatus@#{@botname}"
            self.handleBotStatusMessage(msg.text, msg.author.id, msg.chat.id)
        when '/events', "/events@#{@botname}"
            self.handleEventsMessage(msg.text, msg.author.id, msg.chat.id)
        when '/help', "/help@#{@botname}"
            self.handleHelpMessage(msg.text, msg.author.id, msg.chat.id)
        else
            if commandTarget == @botname then
                self.pushMessage(I18n.t('unknown_command'), msg.chat.id)
            end
        end
    end

    def pushMessage(msg, chatId, reply_markup = nil, silent = false)
        log("silent is #{silent} for #{msg}") if silent
        reply_markup = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [%w(/subscribe /help /setday /botstatus), %w(/unsubscribe /events /settime /mystatus)], one_time_keyboard: false) if reply_markup.nil?
        begin
            @bot_instance.api.send_message(chat_id: chatId, text: msg, reply_markup: reply_markup, disable_notification: silent) unless @bot_instance.nil?
        rescue Exception => e
            log("Exception received #{e}")
        end
    end
end
