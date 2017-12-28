#!/usr/bin/env ruby

require 'yaml'
require 'i18n'

require_relative './data'
require_relative './bot'
require_relative './ics'

$defaultConfigFile = File.join File.dirname(__FILE__), '..', 'config', 'conf.yml'

$config = nil
$events = nil
$data = nil
$bot = nil

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

def handlePendingEvents(events)
    events.each do |event|
        $bot.notify(event)
    end
end

configFilename = getCommandlineArgument('--config').nil? ? $defaultConfigFile : getCommandlineArgument('--config')
locale = getCommandlineArgument('--lang').to_sym unless getCommandlineArgument('--lang').nil?
$config = loadConfig(configFilename)

I18n.load_path = Dir['lang/*.yml']
I18n.backend.load_translations
I18n.default_locale = :de
I18n.locale = locale unless locale.nil?

$data = DataStore.new($config['db_path'])
$events = ICS::Calendar.new
$events.loadEvents(ICS::FileParser::parseICS($config['ics_path']))
$bot = Bot.new($config['bot_token'], $data, $events)

puts "Found #{$events.getEvents.length} events."

$eventThread = nil
$databaseThread = nil
$botThread = nil

$eventThreadBlock  = lambda do
    while(true) do
        handlePendingEvents($events.getEvents)
        sleep 1
    end
end
$databaseThreadBlock = lambda do
    while(true) do
        puts "#{Time.now.strftime('%H:%M:%S')}: Syncing database..."
        $data.flush
        puts "Syncing done..."
        puts "sleeping #{$config['flush_interval']} seconds"
        sleep($config['flush_interval'])
    end
end
$botThreadBlock = lambda do
    begin
    $bot.run
    rescue Exception => e
        $execute = false
    end
end

def startThreads
    $eventThread = Thread.fork &$eventThreadBlock if $eventThread.nil? or not $eventThread.alive?
    $databaseThread = Thread.fork &$databaseThreadBlock if $databastThread.nil? or not $databaseThread.alive?
    $botThread = Thread.fork &$botThreadBlock if $botThread.nil? or not $botThread.alive?
end

$execute = true
startThreads
while($execute) do
    begin
        sleep 1
    rescue Exception => e
        $execute = false
        puts "Shutdown signal received"
    end
    unless $databaseThread.alive?
        puts "Database-Thread lost"
    end
    unless $eventThread.alive?
        puts "Event-Thread lost"
    end
    unless $botThread.alive?
        puts "Bot-Thread lost"
    end
end

puts "Shutting down..."
$eventThread.kill if $eventThread.alive?
$databaseThread.kill if $databaseThread.alive?
$botThread.kill if $botThread.alive?
puts "Shutdown complete."