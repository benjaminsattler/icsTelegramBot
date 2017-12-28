#!/usr/bin/env ruby

require 'yaml'
require 'i18n'

require_relative './data'
require_relative './bot'
require_relative './ics'

$defaultConfigFile = File.join File.dirname(__FILE__), '..', 'config', 'conf.yml'
$configFile = nil
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

$config = loadConfig(getCommandlineArgument('--config').nil? ? $defaultConfigFile : getCommandlineArgument('--config'))

I18n.load_path = Dir['lang/*.yml']
I18n.backend.load_translations
I18n.default_locale = :de
I18n.locale = getCommandlineArgument('--lang').to_sym unless getCommandlineArgument('--lang').nil?

$data = DataStore.new($config['db_path'])
$events = ICS::Calendar.new
$events.loadEvents(ICS::FileParser::parseICS($config['ics_path']))
$bot = Bot.new($config['bot_token'], $data, $events)

puts "Found #{$events.getEvents.length} events."

Thread.fork do
    while(true) do
        handlePendingEvents($events.getEvents)
        sleep 1
    end
end

Thread.fork do
    while(true) do
        puts "Syncing database..."
        $data.flush
        puts "Syncing done..."
        sleep(10)
    end
end

$bot.run
def handlePendingEvents(events)
    events.each do |event|
        Bot.notify(event)
    end
end