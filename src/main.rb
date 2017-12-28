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
        Bot.notify(event)
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

eventThread = Thread.fork do
    while(true) do
        handlePendingEvents($events.getEvents)
        sleep 1
    end
end

databaseThread = Thread.fork do
    while(true) do
        puts "Syncing database..."
        $data.flush
        puts "Syncing done..."
        sleep($config.flush_interval)
    end
end

$execute = true
botThread = Thread.fork do
    begin
    $bot.run
    rescue Exception => e
        $execute = false
    end
end


while($execute) do
    begin
        sleep 1
    rescue Exception => e
        $execute = false
        puts "Shutdown signal received"
    end
end

puts "Shutting down..."
eventThread.kill if eventThread.alive?
databaseThread.kill if databaseThread.alive?
botThread.kill if botThread.alive?
puts "Shutdown complete."