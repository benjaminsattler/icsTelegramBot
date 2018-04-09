require 'commands/command'
require 'commands/mixins/EventMessagePusher'
require 'util'

require 'i18n'

class EventsCommand < Command
    include EventMessagePusher
    def process(msg, userid, chatid, silent)
        command, *args = msg.split(/\s+/)
        count = 10
        calendar = 1
        if /^[0-9]+$/.match(args[0]) then
            count = args[0].to_i
        else
            unless args.empty? then
                self.bot.pushMessage(I18n.t('errors.events.command_invalid'), chatid)
                return
            end
        end

        if /^[0-9]+$/.match(args[1]) then
            calendar = args[1].to_i
            if calendar > self.calendars.length or calendar < 1 or self.calendars[calendar].nil? then
                self.bot.pushMessage(I18n.t('errors.events.command_invalid'), chatid)
                return
            end
        else
            unless args.empty? then
                self.bot.pushMessage(I18n.t('errors.events.command_invalid'), chatid)
                return
            end
        end
        self.pushEventsDescription(self.calendars[calendar].getEvents(count), userid, chatid)
    end
end
