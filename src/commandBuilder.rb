require 'commands/command'
require 'commands/botstatus'
require 'container'

class CommandBuilder

    def build(commandClass)
        if Object.const_get(commandClass) < Command then
            return Object.const_get(commandClass)
                .new
                .setBot(Container::get('bot'))
                .setDataStore(Container::get('datastore'))
                .setCalendars(Container::get('calendars'))
        end
    end

end
