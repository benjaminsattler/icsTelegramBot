require 'log'
require 'query/SetTimeQuery'
require 'query/SetDayQuery'
require 'util'
require 'commandBuilder'

require 'telegram/bot'
require 'i18n'
require 'multitrap'

class Bot

    attr_reader :bot_instance, :uptime_start
    
    @data = nil
    @calendars = nil
    @bot_instance = nil
    @token = nil
    @uptime_start = nil
    @pendingQueries = nil
    @adminUsers = nil
    @botname = nil

    def initialize(token, dataStore, calendars, adminUsers)
        @token = token
        @data = dataStore
        @calendars = calendars
        @pendingQueries = {}
        @adminUsers = adminUsers
    end

    def pingAdminUsers(users)
        users.each { |user_id| self.handleBotStatusMessage(nil, user_id, user_id, true) } 
    end
    
    def storePendingQuery(message_id, query)
        @pendingQueries[message_id] = query
    end

    def removePendingQuery(qry)
        @pendingQueries.reject! { |key, val| val == qry }
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
            self.pingAdminUsers(@adminUsers)
            while not Thread.current[:stop]
                @bot_instance.listen do |message| 
                    self.handleIncoming({msg: message})
                end
            end
        end
    end
    
    def handleSetDayMessage(msg, userid, chatid)
        CommandBuilder::build('SetDayCommand')
            .process(msg, userid, chatid, false)
    end
    
    def handleSetTimeMessage(msg, userid, chatid)
        CommandBuilder::build('SetTimeCommand')
            .process(msg, userid, chatid, false)
    end

    def handleEventsMessage(msg, userid, chatid)
        CommandBuilder::build('EventsCommand')
            .process(msg, userid, chatid, false)
            end

    def handleBotStatusMessage(msg, userid, chatid, silent = false)
        CommandBuilder::build('BotStatusCommand')
            .process(msg, userid, chatid, silent)
    end

    def handleMyStatusMessage(msg, userid, chatid)
        CommandBuilder::build('MyStatusCommand')
            .process(msg, userid, chatid, false)
    end

    def handleHelpMessage(msg, userid, chatid)
        CommandBuilder::build('HelpCommand')
            .process(msg, userid, chatid, false)
    end

    def handleSubscribeMessage(msg, userid, chatid)
        CommandBuilder::build('SubscribeCommand')
            .process(msg, userid, chatid, false)
    end

    def handleUnsubscribeMessage(msg, userid, chatid)
        CommandBuilder::build('UnsubscribeCommand')
            .process(msg, userid, chatid, false)
    end
    
    def notify(event)
        @data.getAllSubscribers.each do |subscriber|
            if !subscriber[:notifiedEvents].include?(event.id) && (event.date - Date.today()).to_i == subscriber[:notificationday] && subscriber[:notificationtime][:hrs] == Time.new.hour && subscriber[:notificationtime][:min] == Time.new.min then
                self.pushMessage(I18n.t('event.reminder', summary: event.summary, days_to_event: subscriber[:notificationday], date_of_event: event.date.strftime('%d.%m.%Y')), subscriber[:telegram_id])
                subscriber[:notifiedEvents].push(event.id)
            end
        end
    end

    def handleIncoming(interaction)
        msg = interaction[:msg]
        case msg
        when Telegram::Bot::Types::Message
            self.handleTextMessage(msg)
        when Telegram::Bot::Types::CallbackQuery
            self.handleCallbackQuery(msg)
        else
            log("Received an unknown interaction type #{msg.class}. Dump is #{msg.inspect}")
            #self.pushMessage(I18n.t('unknown_command', msg.chat.id))
        end
    end

    def handleCallbackQuery(msg)
        qry = self.getPendingQuery(msg.message.message_id) 
        qry.respondTo(msg) unless qry.nil?
    end

    def hasPendingQuery(message_id)
        qry = @pendingQueries[message_id]
        return false if qry.nil?
        return true
    end
    
    def getPendingQuery(message_id)
        @pendingQueries[message_id]
    end
    
    def handleTextMessage(msg)
        if msg.nil? or msg.text.nil? then
            return
        end
        command, *args = msg.text.split(/\s+/)
        commandTarget = command.include?('@') ? command.split('@')[1] : nil
        log("command target is #{commandTarget}")
        case command
        when '/start', "/start@#{@botname}"
            self.pushMessage(I18n.t('start', botname: @bot_instance.api.getMe()['result']['username']), msg.chat.id)
        when '/subscribe', "/subscribe@#{@botname}"
            self.handleSubscribeMessage(msg.text, msg.from.id, msg.chat.id)
        when '/setday'
            self.handleSetDayMessage(msg.text, msg.from.id, msg.chat.id)
        when '/settime', "/settime@#{@botname}"
            self.handleSetTimeMessage(msg.text, msg.from.id, msg.chat.id)
        when '/unsubscribe', "/unsubscribe@#{@botname}"
            self.handleUnsubscribeMessage(msg.text, msg.from.id, msg.chat.id)
        when '/mystatus', "/mystatus@#{@botname}"
            self.handleMyStatusMessage(msg.text, msg.from.id, msg.chat.id)
        when '/botstatus', "/botstatus@#{@botname}"
            self.handleBotStatusMessage(msg.text, msg.from.id, msg.chat.id)
        when '/events', "/events@#{@botname}"
            self.handleEventsMessage(msg.text, msg.from.id, msg.chat.id)
        when '/help', "/help@#{@botname}"
            self.handleHelpMessage(msg.text, msg.from.id, msg.chat.id)
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
