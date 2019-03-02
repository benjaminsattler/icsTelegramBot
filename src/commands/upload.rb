# frozen_string_literal: true

require 'commands/command'
require 'messages/message'

require 'i18n'

##
# This class represents an uploaded file
# given by the user.
class UploadCommand < Command
  def initialize(message_sender, file_downloader, file_writer, file_parser)
    super(message_sender)
    @file_downloader = file_downloader
    @file_writer = file_writer
    @file_parser = file_parser
  end

  def process(msg, userid, chatid, orig_obj)
    bot = Container.get(:bot)
    datastore = Container.get(:dataStore)
    filename = orig_obj.document.file_name

    unless @file_parser.supported?(filename)
      @message_sender.process(
        Message.new(
          i18nkey: 'errors.upload.unsupported',
          i18nparams: {},
          id_recv: chatid,
          markup: nil
        )
      )
      return
    end

    begin
      resp = bot.get_file(msg)
    rescue StandardError => e
      raise e
    end

    file_url = format(
      'https://api.telegram.org/file/bot%s/%s',
      bot.token,
      resp['result']['file_path']
    )
    file_contents = @file_downloader.get(file_url)
    if file_contents.nil?
      @message_sender.process(
        Message.new(
          i18nkey: 'errors.upload.empty_file_download',
          i18nparams: {},
          id_recv: chatid,
          markup: nil
        )
      )
      return
    end

    events = []
    begin
      events = @file_parser.parse_string(file_contents)
    rescue StandardError => err
      @message_sender.process(
        Message.new(
          i18nkey: 'errors.upload.parse_error',
          i18nparams: {
            error: err
          },
          id_recv: chatid,
          markup: nil
        )
      )
      return
    end
    file_path = format(
      '/assets/%s',
      orig_obj.document.file_name
    )
    @file_writer.write(file_contents, file_path)
    description = orig_obj.caption
    description = orig_obj.document.file_name if description.nil?
    datastore.add_calendar(
      display_name: description,
      filename: file_path,
      owner: userid
    )

    @message_sender.process(
      Message.new(
        i18nkey: 'upload.success',
        i18nparams: {
          num_events: events.length,
          calendar_name: description
        },
        id_recv: chatid,
        markup: nil
      )
    )
    Container.get(:watchdog).kill_by_name('event')
  end
end
