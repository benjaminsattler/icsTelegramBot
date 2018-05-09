class IncomingMessage

    attr_reader :text, :author, :chat

    @text = nil
    @author = nil
    @chat = nil
    def initialize(text, author, chat)
        @text = text
        @author = author
        @chat = chat
    end
end
