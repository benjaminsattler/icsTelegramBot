# frozen_string_literal: true

require 'commands/command'
require 'container'
require 'messages/message'
require 'util'

require 'i18n'

##
# This class represents the /mystatus command
# given by the user.
class MyStatusCommand < Command
  def process(_msg, userid, chatid, _silent)
    data_store = Container.get(:dataStore)
    calendars = Container.get(:calendars)
    subscriptions = data_store.subscriptions_for_id(userid)
    if subscriptions.empty?
      @message_sender.process(
        Message.new(
          i18nkey: 'status.not_subscribed',
          i18nparams: {},
          id_recv: chatid,
          markup: nil
        )
      )
      return
    end
    text = +''
    subscriptions.each do |subscription|
      reminder_time = "#{Util.pad(subscription[:notificationtime][:hrs], 2)}"\
                      ":#{Util.pad(subscription[:notificationtime][:min], 2)}"
      calendar_name = calendars[subscription[:eventlist_id]][:description]
      text << format(
        "%s; %s: %s\n",
        subscription[:notificationday],
        reminder_time,
        calendar_name
      )
    end
    @message_sender.process(
      Message.new(
        i18nkey: 'status.subscribed',
        i18nparams: {
          subscription_info: text
        },
        id_recv: chatid,
        markup: nil
      )
    )
  end
end
