# frozen_string_literal: true

require 'commands/command'

require 'i18n'

##
# This class represents a /unsubscribe command
# given by the user.
class UnsubscribeCommand < Command
  include EventMessagePusher

  def process(msg, userid, chatid, orig)
    _command, *args = msg.split(/\s+/)
    calendars = Container.get(:calendars)
    bot = Container.get(:bot)
    if args.empty?
      @message_sender.process(
        I18n.t('unsubscribe.choose_calendar'),
        chatid,
        calendar_buttons
      )
      return
    end
    begin
      bot.bot_instance.api.editMessageReplyMarkup(
        chat_id: orig.message.chat.id,
        message_id: orig.message.message_id,
        reply_markup: Telegram::Bot::Types::InlineKeyboardMarkup.new(
          inline_keyboard: []
        )
      )
    rescue StandardError
    end
    calendar_id = begin
                    Integer(args[0])
                  rescue StandardError
                    -1
                  end
    if calendars[calendar_id].nil?
      @message_sender.process(
        I18n.t(
          'errors.unsubscribe.command_invalid',
          calendar_id: calendars.keys.first,
          calendar_name: calendars.values.first[:description]
        ),
        chatid
      )
      return
    end
    Container.get(:dataStore).remove_subscriber(
      telegram_id: userid,
      eventlist_id: calendar_id
    )
    @message_sender.process(
      I18n.t(
        'confirmations.unsubscribe_success',
        calendar_name: calendars[calendar_id][:description]
      ),
      chatid
    )
  end

  def calendar_buttons
    calendars = Container.get(:calendars)
    btns = calendars.values.map do |calendar|
      [Telegram::Bot::Types::InlineKeyboardButton.new(
        text: calendar[:description],
        callback_data: "/unsubscribe #{calendar[:calendar_id]}"
      )]
    end
    Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: btns)
  end
end
