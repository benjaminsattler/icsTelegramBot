class Query
    include Comparable
    attr_reader :given_data, :message_id, :user_id, :chat_id
    
    def initialize(opts)
        @given_data = Array.new
        @message_id = nil
        @user_id = opts[:user_id]
        @chat_id = opts[:chat_id]
        @bot = opts[:bot]
    end

    def respond
        raise NotImplementedError
    end

    def respondTo(msg)
        raise NotImplementedError
    end
    
    def complete?
        raise NotImplementedError
    end

    def start
        raise NotImplementedError
    end
    
    def finish
        raise NotImplementedError
    end

    def getKeyboard
        raise NotImplementedError
    end

    def <=>(another_query)
        raise NotImplementedError
    end
end
