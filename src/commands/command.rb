require 'AbstractClass'

class Command < AbstractClass

    def initialize(messageSender)
        @messageSender = messageSender
    end
    
    def process(msg, userid, chatid, silent)
        raise NotImplementedError
    end
end
