# frozen_string_literal: true

require 'commands/command'

require 'i18n'

##
# This class represents an uploaded file
# given by the user.
class DownloadCommand < Command
  def initialize(message_sender, file_uploader)
    super(message_sender)
    @file_uploader = file_uploader
  end

  def process(msg, _userid, chatid, _orig_obj)
    _command, *args = msg.split(/\s+/)
    calendars = Container.get(:calendars)
    bot = Container.get(:bot)
    calendar_id = args[0]
    if calendar_id.nil?
      @message_sender.process(
        I18n.t(
          'download.choose_calendar'
        ),
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
                    Integer(calendar_id)
                  rescue StandardError
                    -1
                  end
    if calendars[calendar_id].nil?
      @message_sender.process(
        I18n.t(
          'errors.download.command_invalid',
          calendar_id: calendars.keys.first,
          calendar_name: calendars.values.first[:description]
        ),
        chatid
      )
      return
    end

    document = @file_uploader.upload(
      calendars[calendar_id][:ics_path],
      mine_type: 'text/calendar'
    )

    bot.bot_instance.send_document(
      chat_id: chatid,
      document: document
    )
  end

  def calendar_buttons
    calendars = Container.get(:calendars)
    btns = calendars.values.map do |calendar|
      [
        Telegram::Bot::Types::InlineKeyboardButton.new(
          text: calendar[:description],
          callback_data: "/download #{calendar[:calendar_id]}"
        )
      ]
    end
    Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: btns)
  end
end
