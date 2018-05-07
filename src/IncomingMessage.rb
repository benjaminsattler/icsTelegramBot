class IncomingMessage
    @text = nil
    @authorid = nil
    @chatid = nil
    def initialize(text, authorid, chatid)
        @text = text
        @authorid = authorid
        @chatid = chatid
    end
end
