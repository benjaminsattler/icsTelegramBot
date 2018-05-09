require 'workflow/AbstractWorkflow'
require 'workflow/state/Subscribe'
require 'IncomingMessage'
require 'IncomingInlineQuery'
require 'MessageSender'

class SubscribeWorkflow < AbstractWorkflow

    @messageSender = nil
    def initialize(messageSender)
        @messageSender = messageSender
    end

    def start(state, incoming)
        AbstractWorkflow::start(state, incoming)
        return self.progress(state, incoming)
    end

    def progress(state, incoming)
        if state.calendar.nil? then
            if incoming::class <= IncomingInlineQuery then
                state.calendar = incoming.data
            end
            if incoming::class <= IncomingMessage then
                fragments = incoming.text.split(/\s+/)
                # TODO: check calendar reference
                if fragments.length > 1 then
                    state.calendar = fragments[1]
                    return self.finish(state)
                end
                @messageSender.process('Du musst noch einen calendar eingeben!', state.chat.id)
            end
        end

        return state
    end

    def regress(state)
        state.calendar = nil
        return state
    end

    def reset(state)
        state.calendar = nil
        return state
    end

    def finish(state)
        @messageSender.process('ich würde jetzt fertig machen', state.chat.id)
    end
end
