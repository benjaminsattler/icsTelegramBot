#!/usr/bin/env ruby

require 'telegram/bot'
require 'yaml'
require 'i18n'

$events = []
$currentEvent = nil
$incomingMsgQueue = []
$subscribers = []
$defaultConfigFile = File.join File.dirname(__FILE__), '..', 'config', 'conf.yml'
$configFile = nil
$config = nil

def loadConfig(configFile)
    YAML.load_file(configFile)
end

def getCommandlineArgument(argname)
    args = {}
    ARGV.each do |arg|
        matcher = /^([^=]+)=(.+)$/.match(arg)
        if (matcher) then
            args[matcher[1]] = matcher[2]
        else
            args[arg] = true
        end
    end
    args[argname]
end

def cleanLine(line)
    line.strip
end

def splitLine(line)
    parts = line.split(':')
    if parts.length == 1
        {k: nil, v: parts[0]}
    else
        {k:parts[0], v: parts[1]}
    end
end

def parseICSDate(dateString)
    Date.strptime(dateString, '%Y%m%d')
end

def parseICS(file)
    File.open(file, 'r', external_encoding:Encoding::UTF_8) do |file|
        while(line = file.gets) do
            line = cleanLine(line)
            line = splitLine(line)
            k = line[:k]
            v = line[:v]
            case k
            when 'BEGIN'
                case v
                when 'VEVENT'
                    if ($currentEvent.nil?) then
                        $currentEvent = {}
                    else
                        throw('Error: encountered new event without closing previous event')
                    end
                else
                    puts "Unknown BEGIN key #{v}"
                end
            when 'END'
                case v
                when 'VEVENT'
                    if ($currentEvent.nil?) then
                        throw('Error: encountered close event without opened one')
                    else
                        $events.push($currentEvent);
                        $currentEvent = nil;
                    end
                else
                    puts "Unknown BEGIN key #{v}"
                end
            when 'SUMMARY'
                if ($currentEvent.nil?) then
                    throw 'Error: event property found when in no active event'
                else
                    $currentEvent[:summary] = v
                end
            when 'DTSTART;VALUE=DATE'
                if ($currentEvent.nil?) then
                    throw 'Error event property found when in no active event'
                else
                    $currentEvent[:date] = parseICSDate(v)
                end
            end
        end
    end
end

def getDate()
    Date.today
end

def notify(event)
    $subscribers.each do |target|
        if !target[:notifiedEvents].include?(event) && (event[:date] - getDate()).to_i == target[:notificationday] && target[:notificationtime][:hrs] == Time.new.hour && target[:notificationtime][:min] == Time.new.min then
            pushMessage(I18n.t('event.reminder', summary: event[:summary], days_to_event: target[:notificationday], date_of_event: event[:date].strftime('%d.%m.%Y')), target[:chatId], target[:bot])
            target[:notifiedEvents].push(event)
        end
    end
end

def tick
    handleIncomingMessages()
    handlePendingEvents()
end

def handlePendingEvents()
    $events.each do |event|
        notify(event)
    end
end

def handleIncomingMessages()
    $incomingMsgQueue.reject! do |msg|
        handleIncoming(msg)
        true
    end
end

def handleSetDayMessage(msg, bot)
    command, *args = msg.text.split(/\s+/)
    target = $subscribers.select { |subscriber| subscriber[:chatId] == msg.from.id }
    if target.empty? then
        pushMessage(I18n.t('errors.no_subscription_teaser', command: '/setday'), msg.chat.id, bot)
    else
        target.each do |subscriber| 
            days = 1
            if /^[0-9]+$/.match(args[0]) then
                days = args[0].to_i
            else
                pushMessage(I18n.t('errors.setday.command_invalid'), msg.chat.id, bot)
                return
            end

            if days > 14 then
                pushMessage(I18n.t('errors.setday.day_too_early'), msg.chat.id, bot)
                return
            end
            if days < 0 then
                pushMessage(I18n.t('errors.setday.day_in_past'), msg.chat.id, bot)
                return
            end

            subscriber[:notificationday] = days
            subscriber[:notifiedEvents].clear
            if subscriber[:notificationday] == 0 then
                pushMessage(I18n.t('confirmations.setdatetime_success_sameday', reminder_time: "#{subscriber[:notificationtime][:hrs]}:#{subscriber[:notificationtime][:min]}"), msg.chat.id, bot)
            elsif subscriber[:notificationday] == 1 then
                pushMessage(I18n.t('confirmations.setdatetime_success_precedingday', reminder_time: "#{subscriber[:notificationtime][:hrs]}:#{subscriber[:notificationtime][:min]}"), msg.chat.id, bot)
            else
                pushMessage(I18n.t('confirmations.setdatetime_success_otherday', reminder_day_count: subscriber[:notificationday], reminder_time: "#{subscriber[:notificationtime][:hrs]}:#{subscriber[:notificationtime][:min]}"), msg.chat.id, bot)
            end
        end
    end
end

def handleSetTimeMessage(msg, bot)
    command, *args = msg.text.split(/\s+/)
    target = $subscribers.select { |subscriber| subscriber[:chatId] == msg.from.id }
    if target.empty? then
        pushMessage(I18n.t('errors.no_subscription_teaser', command: '/settime'), msg.chat.id, bot)
    else
        target.each do |subscriber| 
            hrs = 20
            min = 0
            matcher = /^([0-9]+):([0-9]+)$/.match(args[0])
            if !matcher.nil? then
                if matcher[1].to_i < 1 || matcher[1].to_i > 23 || matcher[2].to_i < 0 || matcher[2].to_i > 59 then
                    pushMessage(I18n.t('errors.settime.command_invalid'), msg.chat.id, bot)    
                    return
                else
                    hrs = matcher[1].to_i
                    min = matcher[2].to_i
                end
            else
                pushMessage(I18n.t('errors.settime.command_invalid'), msg.chat.id, bot)
                return
            end

            subscriber[:notificationtime] = {hrs: hrs, min: min}
            subscriber[:notifiedEvents].clear
            if subscriber[:notificationday] == 0 then
                pushMessage(I18n.t('confirmations.setdatetime_success_sameday', reminder_time: "#{subscriber[:notificationtime][:hrs]}:#{subscriber[:notificationtime][:min]}"), msg.chat.id, bot)
            elsif subscriber[:notificationday] == 1 then
                pushMessage(I18n.t('confirmations.setdatetime_success_precedingday', reminder_time: "#{subscriber[:notificationtime][:hrs]}:#{subscriber[:notificationtime][:min]}"), msg.chat.id, bot)
            else
                pushMessage(I18n.t('confirmations.setdatetime_success_otherday', reminder_day_count: subscriber[:notificationday], reminder_time: "#{subscriber[:notificationtime][:hrs]}:#{subscriber[:notificationtime][:min]}"), msg.chat.id, bot)
            end
        end
    end
end

def handleEventsMessage(msg, bot)
    command, *args = msg.text.split(/\s+/)
    count = 10
    if /^[0-9]+$/.match(args[0]) then
        count = args[0].to_i
    else
        unless args.empty? then
            pushMessage(I18n.t('errors.events.command_invalid'), msg.chat.id, bot)
            return
        end
    end
    pushEventsDescription($events.take(count), msg.chat.id, bot)
end

def pushEventsDescription(events, id, bot)
    count = events.length
    pushMessage(I18n.t('events.listing_intro_multiple', total:count), id, bot) unless count == 1
    pushMessage(I18n.t('events.listing_intro_one'), id, bot) if count == 1
    pushMessage(I18n.t('events.listing_intro_empty'), id, bot) if count == 0
    events
        .take(count)
        .each { |event|  pushEventDescription(event, id, bot)}
end

def pushEventDescription(event, id, bot)
    pushMessage("#{event[:date].strftime('%d.%m.%Y')}: #{event[:summary]}", id, bot)
end

def handleHelpMessage(msg, bot)
    pushMessage(I18n.t('help.msg1'), msg.chat.id, bot)
    pushMessage(I18n.t('help.msg2'), msg.chat.id, bot)
    pushMessage(I18n.t('help.msg3', last_event_date: $events.last[:date].strftime("%d.%m.%Y")), msg.chat.id, bot)
    pushMessage(I18n.t('help.start'), msg.chat.id, bot)
    pushMessage(I18n.t('help.settime'), msg.chat.id, bot)
    pushMessage(I18n.t('help.setday'), msg.chat.id, bot)
    pushMessage(I18n.t('help.subscribe'), msg.chat.id, bot)
    pushMessage(I18n.t('help.unsubscribe'), msg.chat.id, bot);
    pushMessage(I18n.t('help.events'), msg.chat.id, bot)
    pushMessage(I18n.t('help.help'), msg.chat.id, bot);
end

def handleIncoming(interaction)
    bot = interaction[:bot]
    msg = interaction[:msg]
    command, *args = msg.text.split(/\s+/)
    case command
    when '/start'
        reply_markup = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [%w(/subscribe /setday /help), %w(/unsubscribe /settime /events)], one_time_keyboard: false)
        pushMessage(I18n.t('start'), msg.chat.id, bot, reply_markup)
    when '/subscribe'
        isSubbed = $subscribers.select { |subscriber| subscriber[:chatId] == msg.from.id }
        if (isSubbed.empty?) then 
            $subscribers.push({chatId: msg.from.id, bot:bot, notificationday: 1, notificationtime: {hrs: 20, min: 00}, notifiedEvents: []})
            pushMessage(I18n.t('confirmations.subscribe_success'), msg.chat.id, bot)
            pushEventsDescription([$events.first], msg.from.id, bot)
        else
            pushMessage(I18n.t('errors.subscribe.double_subscription'), msg.chat.id, bot);
        end
    when '/setday'
        handleSetDayMessage(msg, bot)
    when '/settime'
        handleSetTimeMessage(msg, bot)
    when '/unsubscribe'
        $subscribers.reject! { |target| target[:chatId] == msg.chat.id }
        pushMessage(I18n.t('confirmations.unsubscribe_success'), msg.chat.id, bot)
    when '/events'
        handleEventsMessage(msg, bot)
    when '/help'
        handleHelpMessage(msg, bot)
    else
        pushMessage(I18n.t('unknown_command'), msg.chat.id, bot)
    end
end

def pushMessage(msg, chatId, bot, reply_markup = nil)
    bot.api.send_message(chat_id: chatId, text: msg, reply_markup: reply_markup)
end

$shouldQuit = false
$config = loadConfig(getCommandlineArgument('--config').nil? ? $defaultConfigFile : getCommandlineArgument('--config'))

I18n.load_path = Dir['lang/*.yml']
I18n.backend.load_translations
I18n.default_locale = :de
I18n.locale = getCommandlineArgument('--lang').to_sym unless getCommandlineArgument('--lang').nil?

parseICS($config['ics_path'])
puts "Found #{$events.length} events."

$events = $events
    .reject { |event| event[:date].year <= getDate().year && event[:date].yday < getDate().yday }
    .sort_by { |event| [event[:date].year, event[:date].yday] }
Thread.fork do 
    Telegram::Bot::Client.run($config['bot_token']) do |bot|
        bot.listen do |message| 
            $incomingMsgQueue.push({msg: message, bot: bot})
            puts "message length in telegram thread: #{$incomingMsgQueue.length}"
        end
    end
end

while (!$shouldQuit) do
    puts "message length in loop thread: #{$incomingMsgQueue.length}"
    tick
    sleep 1 
end