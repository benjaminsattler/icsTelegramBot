#!/usr/bin/env ruby

require 'yaml'
require 'i18n'

require_relative './data'
require_relative './bot'
require_relative './ics'
require_relative './watchdog'

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

$watchdog = Watchdog.new
$eventThread = nil
$databaseThread = nil
$botThread = nil

$eventThreadBlock  = lambda do
    while(not Thread.current[:stop]) do
        $events.getEvents.each do |event|
            $bot.notify(event)
        end
        sleep 1
    end
end

$databaseThreadBlock = lambda do
    run = true
    while(run) do
        seconds = $config['flush_interval']
        while(seconds > 0 && run) do
            sleep 1
            seconds = seconds - 1
            run = false if Thread.current[:stop]
        end
        puts "#{Time.now.strftime('%H:%M:%S')}: Syncing database..."
        $data.flush
        puts "Syncing done..."
    end
end
$botThreadBlock = lambda do
    begin
    $bot.run
    rescue Exception => e
        $execute = false
    end
end

$execute = true
$watchdog.watch([{
    name: 'Bot-Thread',
    thr: $botThreadBlock
}, {
    name: 'Database-Thread',
    thr: $databaseThreadBlock
}, {
    name: 'Event-Thread',
    thr: $eventThreadBlock
}])

Signal.trap("TERM") do
    $execute = false
    puts "Shutdown signal received"
    $watchdog.stop
end

while($execute) do
    sleep 1
end

puts "Shutdown complete."