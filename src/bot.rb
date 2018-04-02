require 'log'
require 'query/settime'
require 'query/setday'
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
        command, *args = msg.split(/\s+/)
        subscriber = @data.getSubscriberById(userid)
        if subscriber.nil? then
            self.pushMessage(I18n.t('errors.no_subscription_teaser', command: '/setday'), chatid)
        else
            if args.empty? then
                inline = SetDayQuery.new({user_id: userid, chat_id: chatid, bot: self})
                inline.start
                return
            else
                days = 1
                if /^[0-9]+$/.match(args.first) then
                    days = args.first.to_i
                else
                    self.pushMessage(I18n.t('errors.setday.command_invalid'), chatid)
                    return
                end
        
                if days > 14 then
                    self.pushMessage(I18n.t('errors.setday.day_too_early'), chatid)
                    return
                end
                if days < 0 then
                    self.pushMessage(I18n.t('errors.setday.day_in_past'), chatid)
                    return
                end
        
                subscriber[:notificationday] = days
                subscriber[:notifiedEvents].clear
                @data.updateSubscriber(subscriber)
                reminder_time = "#{pad(subscriber[:notificationtime][:hrs], 2)}:#{pad(subscriber[:notificationtime][:min], 2)}"
                if subscriber[:notificationday] == 0 then
                    self.pushMessage(I18n.t('confirmations.setdatetime_success_sameday', reminder_time: reminder_time), chatid)
                elsif subscriber[:notificationday] == 1 then
                    self.pushMessage(I18n.t('confirmations.setdatetime_success_precedingday', reminder_time: reminder_time), chatid)
                else
                    self.pushMessage(I18n.t('confirmations.setdatetime_success_otherday', reminder_day_count: subscriber[:notificationday], reminder_time: reminder_time), chatid)
                end
            end
        end
    end
    
    def handleSetTimeMessage(msg, userid, chatid)
        CommandBuilder::build('SetTimeCommand')
            .process(msg, userid, chatid, false)
    end

    def handleEventsMessage(msg, userid, chatid)
        command, *args = msg.split(/\s+/)
        count = 10
        calendar = 1
        if /^[0-9]+$/.match(args[0]) then
            count = args[0].to_i
        else
            unless args.empty? then
                self.pushMessage(I18n.t('errors.events.command_invalid'), chatid)
                return
            end
        end

        if /^[0-9]+$/.match(args[1]) then
            calendar = args[1].to_i
            if calendar > @calendars.length or calendar < 1 or @calendars[calendar].nil? then
                self.pushMessage(I18n.t('errors.events.command_invalid'), chatid)
                return
            end
        else
            unless args.empty? then
                self.pushMessage(I18n.t('errors.events.command_invalid'), chatid)
                return
            end
        end
        self.pushEventsDescription(@calendars[calendar].getEvents(count), userid, chatid)
    end

    def handleBotStatusMessage(msg, userid, chatid, silent = false)
        CommandBuilder::build('BotStatusCommand')
            .process(msg, userid, chatid, silent)
    end

    def handleMyStatusMessage(msg, userid, chatid)
        CommandBuilder::build('MyStatusCommand')
            .process(msg, userid, chatid, false)
    end

    def pushEventsDescription(events, userid, chatid)
        count = events.length
        text = Array.new
        text << I18n.t('events.listing_intro_multiple', total:count) unless count == 1
        text << I18n.t('events.listing_intro_one') if count == 1
        text << I18n.t('events.listing_intro_empty') if count == 0
        self.pushMessage(text.join("\n"), chatid)
        events
            .take(count)
            .each { |event|  self.pushEventDescription(event, chatid)}
    end

    def pushEventDescription(event, chatid)
        self.pushMessage("#{event.date.strftime('%d.%m.%Y')}: #{event.summary}", chatid)
    end

    def handleHelpMessage(msg, userid, chatid)
        text = Array.new
        text << I18n.t('help.intro', last_event_date: @calendars.getLeastRecentEvent.date.strftime("%d.%m.%Y"))
        text << I18n.t('help.start')
        text << ""
        text << I18n.t('help.subscribe')
        text << I18n.t('help.unsubscribe')
        text << ""
        text << I18n.t('help.settime')
        text << I18n.t('help.setday')
        text << ""
        text << I18n.t('help.events')
        text << ""
        text << I18n.t('help.botstatus')
        text << I18n.t('help.mystatus')
        text << ""
        text << I18n.t('help.help')
        self.pushMessage(text.join("\n"), chatid)
    end

    def handleSubscribeMessage(msg, userid, chatid)
        isSubbed = @data.getSubscriberById(userid)
        if (isSubbed.nil?) then 
            @data.addSubscriber({telegram_id: userid, notificationday: 1, notificationtime: {hrs: 20, min: 0}, notifiedEvents: []})
            self.pushMessage(I18n.t('confirmations.subscribe_success'), chatid)
            self.pushEventsDescription(@calendars[1].getEvents(1), userid, chatid)
        else
            self.pushMessage(I18n.t('errors.subscribe.double_subscription'), chatid);
        end
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
            @data.removeSubscriber(msg.from.id)
            self.pushMessage(I18n.t('confirmations.unsubscribe_success'), msg.chat.id)
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
