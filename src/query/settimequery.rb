require 'query/query'

class SetTimeQuery < Query
    
    def initialize(opts)
        super(opts)
    end

    def respond
        data = Array.new
        data << (@given_data[0].nil? ? '_' : @given_data[0])
        data << (@given_data[1].nil? ? '_' : @given_data[1])
        data << ':'
        data << (@given_data[2].nil? ? '_' : @given_data[2])
        data << (@given_data[3].nil? ? '_' : @given_data[3])
        response = I18n.t('settime.command_inline', response: data.join(''))
        @bot.bot_instance.api.editMessageText(chat_id: @chat_id, message_id: @message_id, text: response, reply_markup: self.getKeyboard)
    end

    def respondTo(msg)
        data = msg.data
        send_response = false
        if data == 'backspace' then
            unless @given_data.empty?
                @given_data.pop
                send_response = true
            end
        else
            send_response = true
            @given_data.push(data) unless data.nil?
        end
        if (self.complete?) then
            self.finish if send_response
        else
            self.respond if send_response
        end
    end
    
    def complete?
        @given_data.length >= 4
    end

    def start
        response = I18n.t('settime.command_inline', response: '__:__')
        id = @bot.pushMessage(response, @chat_id, self.getKeyboard)
        @message_id = id['result']['message_id'] unless id['result'].nil? or id['result']['message_id'].nil?
        @bot.storePendingQuery(@message_id, self)
    end
    
    def finish
        data = Array.new
        data << (@given_data[0].nil? ? '_' : @given_data[0])
        data << (@given_data[1].nil? ? '_' : @given_data[1])
        data << ':'
        data << (@given_data[2].nil? ? '_' : @given_data[2])
        data << (@given_data[3].nil? ? '_' : @given_data[3])
        self.respond
        @bot.bot_instance.api.editMessageReplyMarkup(chat_id: @chat_id, message_id: @message_id, reply_markup: Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: nil) )
        @bot.removePendingQuery(self)
        @bot.handleSetTimeMessage("/settime #{data.join('')}", @user_id, @chat_id)
    end

    def getKeyboard
        btns = (1..9).map { |n| Telegram::Bot::Types::InlineKeyboardButton.new(text: "#{n}", callback_data: "#{n}") }
        btns.push(Telegram::Bot::Types::InlineKeyboardButton.new(text: '⌫', callback_data: "backspace"))
        btns.push(Telegram::Bot::Types::InlineKeyboardButton.new(text: '0️', callback_data: "0"))
        btns.push(Telegram::Bot::Types::InlineKeyboardButton.new(text: "Abbr.", callback_data: "cancel"))
        Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: [btns[0..2], btns[3..5], btns[6..8], btns[9..10]])
    end

    def <=>(another_query)
        if another_query.class == self.class then
            another_query.message_id - self.message_id
        else
            nil
        end
    end
end
