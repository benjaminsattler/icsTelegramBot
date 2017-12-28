require 'telegram/bot'
require 'i18n'

class Bot

    @incomingMessages = nil
    @data = nil
    @calendar = nil
    @bot_instance = nil
    @token = nil

    def initialize(token, dataStore, calendar)
        @incomingMessages = Array.new
        @token = token
        @data = dataStore
        @calendar = calendar
    end

    def pushMesage(message)
        @incomingMessages.push(message);
    end

    def run
        Telegram::Bot::Client.run(@token) do |bot|
            @bot_instance = bot
            @bot_instance.listen do |message| 
                self.handleIncoming({msg: message})
            end
        end
    end
    
    def handleIncomingMessages()
        @incomingMessages.reject! do |msg|
            Bot.handleIncoming(msg)
            true
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
            if !matcher.nil? then
                if matcher[1].to_i < 1 || matcher[1].to_i > 23 || matcher[2].to_i < 0 || matcher[2].to_i > 59 then
                    self.pushMessage(I18n.t('errors.settime.command_invalid'), msg.chat.id)    
                    return
                else
                    hrs = matcher[1].to_i
                    min = matcher[2].to_i
                end
            else
                self.pushMessage(I18n.t('errors.settime.command_invalid'), msg.chat.id)
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

    def pushEventsDescription(events, id)
        count = events.length
        self.pushMessage(I18n.t('events.listing_intro_multiple', total:count), id) unless count == 1
        self.pushMessage(I18n.t('events.listing_intro_one'), id) if count == 1
        self.pushMessage(I18n.t('events.listing_intro_empty'), id) if count == 0
        events
            .take(count)
            .each { |event|  self.pushEventDescription(event, id)}
    end

    def pushEventDescription(event, id)
        self.pushMessage("#{event.date.strftime('%d.%m.%Y')}: #{event.summary}", id)
    end

    def handleHelpMessage(msg)
        self.pushMessage(I18n.t('help.msg1'), msg.chat.id)
        self.pushMessage(I18n.t('help.msg2'), msg.chat.id)
        self.pushMessage(I18n.t('help.msg3', last_event_date: @calendar.getLeastRecentEvent.date.strftime("%d.%m.%Y")), msg.chat.id)
        self.pushMessage(I18n.t('help.start'), msg.chat.id)
        self.pushMessage(I18n.t('help.settime'), msg.chat.id)
        self.pushMessage(I18n.t('help.setday'), msg.chat.id)
        self.pushMessage(I18n.t('help.subscribe'), msg.chat.id)
        self.pushMessage(I18n.t('help.unsubscribe'), msg.chat.id);
        self.pushMessage(I18n.t('help.events'), msg.chat.id)
        self.pushMessage(I18n.t('help.help'), msg.chat.id);
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
        command, *args = msg.text.split(/\s+/)
        case command
        when '/start'
            reply_markup = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [%w(/subscribe /unsubscribe), %w(/help /events /mystatus)], one_time_keyboard: false)
            self.pushMessage(I18n.t('start'), msg.chat.id, reply_markup)
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
        when '/events'
            self.handleEventsMessage(msg)
        when '/help'
            self.handleHelpMessage(msg)
        else
            self.pushMessage(I18n.t('unknown_command'), msg.chat.id)
        end
    end

    def pushMessage(msg, chatId, reply_markup = nil)
        @bot_instance.api.send_message(chat_id: chatId, text: msg, reply_markup: reply_markup) unless $bot.nil?
    end

end