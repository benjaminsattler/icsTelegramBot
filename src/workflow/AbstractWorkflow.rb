require 'AbstractClass'

class AbstractWorkflow < AbstractClass

    def start(state, incoming)
        state.currentStep = 0
        state.owner = incoming.author
        state.chat = incoming.chat
    end

    def progress(state, incoming)
        raise NotImplementedError
    end

    def regress(state)
        raise NotImplementedError
    end

    def reset()
        raise NotImplementedError
    end

    def finish()
        raise NotImplementedError
    end
end
