require 'commands/command'
require 'commands/BotStatusCommand'
require 'commands/MyStatusCommand'
require 'commands/SetTimeCommand'
require 'commands/SetDayCommand'
require 'commands/EventsCommand'
require 'commands/HelpCommand'
require 'commands/SubscribeCommand'
require 'commands/UnsubscribeCommand'
require 'DependencyDecorator'

class CommandBuilder

    def self::build(commandClass)
        if Object.const_get(commandClass) < Command then
            return DependencyDecorator::process(Object.const_get(commandClass).new)
        end
    end

end
