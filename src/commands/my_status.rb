# frozen_string_literal: true

require 'commands/command'
require 'container'
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
      @message_sender.process(I18n.t('status.not_subscribed'), chatid)
      return
    end
    text = []
    text << I18n.t('status.intro')
    subscriptions.each do |subscription|
      reminder_time = "#{Util.pad(subscription[:notificationtime][:hrs], 2)}"\
                      ":#{Util.pad(subscription[:notificationtime][:min], 2)}"
      calendar_name = calendars[subscription[:eventlist_id]][:description]
      text << if subscription[:notificationday].zero?
                I18n.t(
                  'status.subscribed_sameday',
                  reminder_time: reminder_time,
                  calendar_name: calendar_name
                )
              elsif subscription[:notificationday] == 1
                I18n.t(
                  'status.subscribed_precedingday',
                  reminder_time: reminder_time,
                  calendar_name: calendar_name
                )
              else
                I18n.t(
                  'status.subscribed_otherday',
                  reminder_day_count: subscription[:notificationday],
                  reminder_time: reminder_time,
                  calendar_name: calendar_name
                )
              end
    end
    @message_sender.process(text.join("\n"), chatid)
  end
end
