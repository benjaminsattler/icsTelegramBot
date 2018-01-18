require 'log'
require 'query/settime'
require 'query/setday'

require 'telegram/bot'
require 'i18n'
require 'multitrap'

class Bot

    attr_reader :bot_instance
    
    @data = nil
    @calendar = nil
    @bot_instance = nil
    @token = nil
    @uptime_start = nil
    @pendingQueries = nil
    @adminUsers = nil

    def initialize(token, dataStore, calendar, adminUsers)
        @token = token
        @data = dataStore
        @calendar = calendar
        @pendingQueries = {}
        @adminUsers = adminUsers
    end

    def pingAdminUsers(users)
        users.each { |user_id| self.handleBotStatusMessage(nil, user_id, user_id) } 
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
                bot.api.getMe()
            rescue Exception => e
                log("Please double check Telegram bot token!")
                raise e
            end
            @bot_instance = bot
            self.pingAdminUsers(@adminUsers)
            @bot_instance.listen do |message| 
                self.handleIncoming({msg: message})
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
                if subscriber[:notificationday] == 0 then
                    self.pushMessage(I18n.t('confirmations.setdatetime_success_sameday', reminder_time: "#{subscriber[:notificationtime][:hrs]}:#{subscriber[:notificationtime][:min]}"), chatid)
                elsif subscriber[:notificationday] == 1 then
                    self.pushMessage(I18n.t('confirmations.setdatetime_success_precedingday', reminder_time: "#{subscriber[:notificationtime][:hrs]}:#{subscriber[:notificationtime][:min]}"), chatid)
                else
                    self.pushMessage(I18n.t('confirmations.setdatetime_success_otherday', reminder_day_count: subscriber[:notificationday], reminder_time: "#{subscriber[:notificationtime][:hrs]}:#{subscriber[:notificationtime][:min]}"), chatid)
                end
            end
        end
    end
    
    def handleSetTimeMessage(msg, userid, chatid)
        command, *args = msg.split(/\s+/)
        subscriber = @data.getSubscriberById(userid)
        if subscriber.nil? then
            self.pushMessage(I18n.t('errors.no_subscription_teaser', command: '/settime'), chatid)
        else
            hrs = 20
            min = 0
            matcher = /^([0-9]+):([0-9]+)$/.match(args.first)
            if args.first.nil? then
                inline = SetTimeQuery.new({user_id: userid, chat_id: chatid, bot: self})
                inline.start
                return
            else
                if !matcher.nil? then
                    if matcher[1].to_i >= 0 && matcher[1].to_i <= 23 && matcher[2].to_i >= 0 &&  matcher[2].to_i <= 59 then
                        hrs = matcher[1].to_i
                        min = matcher[2].to_i
                        subscriber[:notificationtime] = {hrs: hrs, min: min}
                        subscriber[:notifiedEvents].clear
                        @data.updateSubscriber(subscriber)
                        if subscriber[:notificationday] == 0 then
                            self.pushMessage(I18n.t('confirmations.setdatetime_success_sameday', reminder_time: "#{subscriber[:notificationtime][:hrs]}:#{subscriber[:notificationtime][:min]}"), chatid)
                        elsif subscriber[:notificationday] == 1 then
                            self.pushMessage(I18n.t('confirmations.setdatetime_success_precedingday', reminder_time: "#{subscriber[:notificationtime][:hrs]}:#{subscriber[:notificationtime][:min]}"), chatid)
                        else
                            self.pushMessage(I18n.t('confirmations.setdatetime_success_otherday', reminder_day_count: subscriber[:notificationday], reminder_time: "#{subscriber[:notificationtime][:hrs]}:#{subscriber[:notificationtime][:min]}"), chatid)
                        end
                        return
                    end
                end
                self.pushMessage(I18n.t('errors.settime.command_invalid'), chatid)
            end
        end
    end

    def handleEventsMessage(msg, userid, chatid)
        command, *args = msg.split(/\s+/)
        count = 10
        if /^[0-9]+$/.match(args[0]) then
            count = args[0].to_i
        else
            unless args.empty? then
                self.pushMessage(I18n.t('errors.events.command_invalid'), chatid)
                return
            end
        end
        self.pushEventsDescription(@calendar.getEvents(count), userid, chatid)
    end

    def handleBotStatusMessage(msg, userid, chatid)
        text = Array.new
        text << I18n.t('botstatus.uptime', uptime: @uptime_start.strftime('%d.%m.%Y %H:%M:%S'))
        text << I18n.t('botstatus.event_count', event_count: @calendar.getEvents.length)
        text << I18n.t('botstatus.subscribers_count', subscribers_count: @data.getAllSubscribers.length)
        self.pushMessage(text.join("\n"), chatid)
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
        text << I18n.t('help.intro', last_event_date: @calendar.getLeastRecentEvent.date.strftime("%d.%m.%Y"))
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

    def notify(event)
        @data.getAllSubscribers.each do |subscriber|
            if !subscriber[:notifiedEvents].include?(event.id) && (event.date - @calendar.getDate()).to_i == subscriber[:notificationday] && subscriber[:notificationtime][:hrs] == Time.new.hour && subscriber[:notificationtime][:min] == Time.new.min then
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
            puts "Received an unknown interaction type #{msg.class}. Dump is #{msg.inspect}"
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
        if msg.nil or msg.text.nil? return
        command, *args = msg.text.split(/\s+/)
        case command
        when '/start'
            self.pushMessage(I18n.t('start', botname: @bot_instance.api.getMe()['result']['username']), msg.chat.id)
        when '/subscribe'
            isSubbed = @data.getSubscriberById(msg.from.id)
            if (isSubbed.nil?) then 
                @data.addSubscriber({telegram_id: msg.from.id, notificationday: 1, notificationtime: {hrs: 20, min: 0}, notifiedEvents: []})
                self.pushMessage(I18n.t('confirmations.subscribe_success'), msg.chat.id)
                self.pushEventsDescription(@calendar.getEvents(1), msg.from.id, msg.chat.id)
            else
                self.pushMessage(I18n.t('errors.subscribe.double_subscription'), msg.chat.id);
            end
        when '/setday'
            self.handleSetDayMessage(msg.text, msg.from.id, msg.chat.id)
        when '/settime'
            self.handleSetTimeMessage(msg.text, msg.from.id, msg.chat.id)
        when '/unsubscribe'
            @data.removeSubscriber(msg.from.id)
            self.pushMessage(I18n.t('confirmations.unsubscribe_success'), msg.chat.id)
        when '/mystatus'
            subscriber = @data.getSubscriberById(msg.from.id)
            if (subscriber.nil?) then 
                self.pushMessage(I18n.t('status.not_subscribed'), msg.chat.id)
            else
                self.pushMessage(I18n.t('status.subscribed', {reminder_day_count: subscriber[:notificationday], reminder_time: "#{subscriber[:notificationtime][:hrs]}:#{subscriber[:notificationtime][:min]}"}), msg.chat.id)
            end
        when '/botstatus'
            self.handleBotStatusMessage(msg.text, msg.from.id, msg.chat.id)
        when '/events'
            self.handleEventsMessage(msg.text, msg.from.id, msg.chat.id)
        when '/help'
            self.handleHelpMessage(msg.text, msg.from.id, msg.chat.id)
        else
            self.pushMessage(I18n.t('unknown_command'), msg.chat.id)
        end
    end

    def pushMessage(msg, chatId, reply_markup = nil)
        reply_markup = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [%w(/subscribe /help /setday /botstatus), %w(/unsubscribe /events /settime /mystatus)], one_time_keyboard: false) if reply_markup.nil?
        @bot_instance.api.send_message(chat_id: chatId, text: msg, reply_markup: reply_markup) unless @bot_instance.nil?
    end
end
