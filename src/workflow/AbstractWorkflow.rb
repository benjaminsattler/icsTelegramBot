require 'AbstractClass'

class AbstractWorkflow < AbstractClass

    def self::start(state, incoming)
        state.currentStep = 0
        state.owner = incoming.author
        state.chat = incoming.chat
    end

    def self::progress(state, incoming)
        raise NotImplementedError
    end

    def self::regress(state)
        raise NotImplementedError
    end

    def self::reset()
        raise NotImplementedError
    end

    def self::finish()
        raise NotImplementedError
    end
end
