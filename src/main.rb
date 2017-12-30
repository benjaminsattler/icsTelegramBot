#!/usr/bin/env ruby

require 'yaml'
require 'i18n'

require_relative './data'
require_relative './bot'
require_relative './ics'
require_relative './watchdog'
require_relative './log'

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
$config = loadConfig(configFilename)
locale = getCommandlineArgument('--lang').to_sym unless getCommandlineArgument('--lang').nil?

Logger.setLogfile($config['log_file'])

I18n.load_path = Dir[File.join(File.dirname(__FILE__), '..', 'lang', '*.yml')]
I18n.backend.load_translations
I18n.default_locale = :de
I18n.locale = locale unless locale.nil?

$data = DataStore.new(File.join(File.dirname(__FILE__), '..', $config['db_path']))
$events = ICS::Calendar.new
$events.loadEvents(ICS::FileParser::parseICS(File.join(File.dirname(__FILE__), '..', $config['ics_path'])))
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
        log("Syncing database...")
        $data.flush
        log("Syncing done...")
    end
end

$botThreadBlock = lambda do
    $bot.run
end


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

$execute = true
Signal.trap("TERM") do
    $execute = false
    log("Shutdown signal received")
    $watchdog.stop
end

while($execute) do
    sleep 1
end

log("Shutdown complete.")