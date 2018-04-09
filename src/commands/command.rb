require 'AbstractClass'

class Command < AbstractClass
    def process(msg, userid, chatid, silent)
        raise NotImplementedError
    end
end
