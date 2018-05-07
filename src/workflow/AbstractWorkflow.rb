require '../AbstractClass'

class AbstractWorkflow < AbstractClass

    @currentStep = nil

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
