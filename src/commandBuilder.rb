require 'commands/command'
require 'commands/BotStatusCommand'
require 'commands/MyStatusCommand'
require 'commands/SetTimeCommand'
require 'commands/SetDayCommand'
require 'commands/EventsCommand'
require 'commands/HelpCommand'
require 'commands/SubscribeCommand'
require 'container'

class CommandBuilder

    def self::build(commandClass)
        if Object.const_get(commandClass) < Command then
            return Object.const_get(commandClass)
                .new
                .setBot(Container::get('bot'))
                .setDataStore(Container::get('datastore'))
                .setCalendars(Container::get('calendars'))
        end
    end

end
