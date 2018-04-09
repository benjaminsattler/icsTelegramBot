require 'AbstractClass'
require 'container'

class DependencyDecorator

    def self::process(commandClass)
        if commandClass.is_a?(AbstractClass) then
            commandClass
                .setBot(Container::get(:bot))
                .setDataStore(Container::get(:dataStore))
                .setCalendars(Container::get(:calendars))
        end

        return commandClass
    end

end
