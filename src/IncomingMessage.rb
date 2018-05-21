class IncomingMessage

    attr_reader :text, :author, :chat, :origObj

    @text = nil
    @author = nil
    @chat = nil
    @origObj = nil
    def initialize(text, author, chat, origObj)
        @text = text
        @author = author
        @chat = chat
        @origObj = origObj
    end
end
