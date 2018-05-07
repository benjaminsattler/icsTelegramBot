require 'AbstractWorkflow'
require 'state/Subscribe'
require '../IncomingMessage'
require '../IncomingInlineQuery'

class SubscribeWorkflow < AbstractWorkflow

    def self::progress(state, incoming)
        if state.@calendar.nil?
            if incoming < IncomingInlineQuery
                state.@calendar = incoming.data
            end
            if incoming < IncomingMessage
                fragments = incoming.text.split(/\s+/)
                state.@calendar = fragments[1]
            end
        end

        return state
    end

    def self::regress(state)
        state.@calendar = nil
        return state
    end

    def self::reset(state)
        state.@calendar = nil
    end

    def self::finish(state)
    end
end
