require 'log'

require 'telegram/bot'
require 'i18n'
require 'multitrap'

class Query
    attr_accessor :given_data, :message_id, :user_id, :pending_command

    def initialize(opts)
        @given_data = opts[:given_data]
        @message_id = opts[:message_id]
        @user_id = opts[:user_id]
        @pending_command = opts[:pending_command]
    end
end

class Bot

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
        @pendingQueries = Array.new
        @adminUsers = adminUsers
    end

    def pingAdminUsers(users)
        users.each { |user_id| self.pushMessage('hi admin! i am alive!', user_id) } 
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
    
    def handleSetDayMessage(msg)
        command, *args = msg.text.split(/\s+/)
        subscriber = @data.getSubscriberById(msg.from.id)
        if subscriber.nil? then
            self.pushMessage(I18n.t('errors.no_subscription_teaser', command: '/setday'), msg.chat.id)
        else
            days = 1
            if /^[0-9]+$/.match(args[0]) then
                days = args[0].to_i
            else
                self.pushMessage(I18n.t('errors.setday.command_invalid'), msg.chat.id)
                return
            end
    
            if days > 14 then
                self.pushMessage(I18n.t('errors.setday.day_too_early'), msg.chat.id)
                return
            end
            if days < 0 then
                self.pushMessage(I18n.t('errors.setday.day_in_past'), msg.chat.id)
                return
            end
    
            subscriber[:notificationday] = days
            subscriber[:notifiedEvents].clear
            @data.updateSubscriber(subscriber)
            if subscriber[:notificationday] == 0 then
                self.pushMessage(I18n.t('confirmations.setdatetime_success_sameday', reminder_time: "#{subscriber[:notificationtime][:hrs]}:#{subscriber[:notificationtime][:min]}"), msg.chat.id)
            elsif subscriber[:notificationday] == 1 then
                self.pushMessage(I18n.t('confirmations.setdatetime_success_precedingday', reminder_time: "#{subscriber[:notificationtime][:hrs]}:#{subscriber[:notificationtime][:min]}"), msg.chat.id)
            else
                self.pushMessage(I18n.t('confirmations.setdatetime_success_otherday', reminder_day_count: subscriber[:notificationday], reminder_time: "#{subscriber[:notificationtime][:hrs]}:#{subscriber[:notificationtime][:min]}"), msg.chat.id)
            end
        end
    end
    
    def handleSetTimeMessage(msg)
        command, *args = msg.text.split(/\s+/)
        subscriber = @data.getSubscriberById(msg.from.id)
        if subscriber.nil? then
            self.pushMessage(I18n.t('errors.no_subscription_teaser', command: '/settime'), msg.chat.id)
        else
            hrs = 20
            min = 0
            matcher = /^([0-9]+):([0-9]+)$/.match(args[0])
            valid_command = true
            if !matcher.nil? then
                if matcher[1].to_i < 1 || matcher[1].to_i > 23 || matcher[2].to_i < 0 || matcher[2].to_i > 59 then
                    valid_command = false
                else
                    hrs = matcher[1].to_i
                    min = matcher[2].to_i
                end
            else
                valid_command = false
                #self.pushMessage(I18n.t('errors.settime.command_invalid'), msg.chat.id)
                #return
            end

            unless valid_command then
                btns = (1..9).map { |n| Telegram::Bot::Types::InlineKeyboardButton.new(text: n, callback_data: "settime #{n}") }
                btns.concat([0, ':'].map { |txt| Telegram::Bot::Types::InlineKeyboardButton.new(text: txt, callback_data: "settime #{txt}") })
                btns.push(Telegram::Bot::Types::InlineKeyboardButton.new(text: "Abbr.", callback_data: "cancel"))
                kb = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: [btns[0..2], btns[3..5], btns[6..8], btns[9..11]])
                puts "message id: #{msg.message_id}"
                @pendingQueries.push(Query.new({user_id: msg.from.id, message_id: msg.from.id, given_data: Array.new,  pending_command: '/settime'}))
                self.pushMessage(I18n.t('errors.settime.command_invalid'), msg.chat.id, kb)
                return
            end
    
            subscriber[:notificationtime] = {hrs: hrs, min: min}
            subscriber[:notifiedEvents].clear
            @data.updateSubscriber(subscriber)
            if subscriber[:notificationday] == 0 then
                self.pushMessage(I18n.t('confirmations.setdatetime_success_sameday', reminder_time: "#{subscriber[:notificationtime][:hrs]}:#{subscriber[:notificationtime][:min]}"), msg.chat.id)
            elsif subscriber[:notificationday] == 1 then
                self.pushMessage(I18n.t('confirmations.setdatetime_success_precedingday', reminder_time: "#{subscriber[:notificationtime][:hrs]}:#{subscriber[:notificationtime][:min]}"), msg.chat.id)
            else
                self.pushMessage(I18n.t('confirmations.setdatetime_success_otherday', reminder_day_count: subscriber[:notificationday], reminder_time: "#{subscriber[:notificationtime][:hrs]}:#{subscriber[:notificationtime][:min]}"), msg.chat.id)
            end
        end
    end
    
    def handleEventsMessage(msg)
        command, *args = msg.text.split(/\s+/)
        count = 10
        if /^[0-9]+$/.match(args[0]) then
            count = args[0].to_i
        else
            unless args.empty? then
                self.pushMessage(I18n.t('errors.events.command_invalid'), msg.chat.id)
                return
            end
        end
        self.pushEventsDescription(@calendar.getEvents(count), msg.chat.id)
    end

    def handleBotStatusMessage(msg)
        text = Array.new
        text << I18n.t('botstatus.uptime', uptime: @uptime_start.strftime('%d.%m.%Y %H:%M:%S'))
        text << I18n.t('botstatus.event_count', event_count: @calendar.getEvents.length)
        text << I18n.t('botstatus.subscribers_count', subscribers_count: @data.getAllSubscribers.length)
        self.pushMessage(text.join("\n"), msg.chat.id)
    end

    def pushEventsDescription(events, id)
        count = events.length
        text = Array.new
        text << I18n.t('events.listing_intro_multiple', total:count) unless count == 1
        text << I18n.t('events.listing_intro_one') if count == 1
        text << I18n.t('events.listing_intro_empty') if count == 0
        self.pushMessage(text.join("\n"), id)
        events
            .take(count)
            .each { |event|  self.pushEventDescription(event, id)}
    end

    def pushEventDescription(event, id)
        self.pushMessage("#{event.date.strftime('%d.%m.%Y')}: #{event.summary}", id)
    end

    def handleHelpMessage(msg)
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
        self.pushMessage(text.join("\n"), msg.chat.id)
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
        command, *args = msg.data.split(/\s+/)
        puts "Chat id: #{msg.message.message_id}"

    end
    
    def handleTextMessage(msg)
        command, *args = msg.text.split(/\s+/)
        case command
        when '/start'
            self.pushMessage(I18n.t('start', botname: @bot_instance.api.getMe()['result']['username']), msg.chat.id)
        when '/subscribe'
            isSubbed = @data.getSubscriberById(msg.from.id)
            if (isSubbed.nil?) then 
                @data.addSubscriber({telegram_id: msg.from.id, notificationday: 1, notificationtime: {hrs: 20, min: 0}, notifiedEvents: []})
                self.pushMessage(I18n.t('confirmations.subscribe_success'), msg.chat.id)
                self.pushEventsDescription(@calendar.getEvents(1), msg.from.id)
            else
                self.pushMessage(I18n.t('errors.subscribe.double_subscription'), msg.chat.id);
            end
        when '/setday'
            self.handleSetDayMessage(msg)
        when '/settime'
            self.handleSetTimeMessage(msg)
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
            self.handleBotStatusMessage(msg)
        when '/events'
            self.handleEventsMessage(msg)
        when '/help'
            self.handleHelpMessage(msg)
        else
            self.pushMessage(I18n.t('unknown_command'), msg.chat.id)
        end
    end

    def pushMessage(msg, chatId, reply_markup = nil)
        reply_markup = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [%w(/subscribe /unsubscribe /botstatus), %w(/help /events /mystatus)], one_time_keyboard: false) if reply_markup.nil?
        @bot_instance.api.send_message(chat_id: chatId, text: msg, reply_markup: reply_markup) unless @bot_instance.nil?
    end
end
