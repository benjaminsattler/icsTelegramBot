class AbstractWorkflow

    @currentStep = nil

    def progress(msg)
        raise NotImplementedError
    end
end
