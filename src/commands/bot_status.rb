# frozen_string_literal: true

require 'commands/command'
require 'container'
require 'messages/message'

require 'i18n'

##
# This class represents a /botstatus command
# given by the user.
class BotStatusCommand < Command
  def initialize(message_sender, sys_info)
    super(message_sender)
    @sys_info = sys_info
  end

  def process(_msg, _userid, chatid, _silent = false)
    calendars = Container.get(:calendars)
    data_store = Container.get(:dataStore)
    bot = Container.get(:bot)
    statistics = bot.statistics.get
    docker_info = @sys_info.docker_info
    os_info = @sys_info.os_info
    calendar_info_text = +''
    calendars.each_pair do |calendar_id, calendar|
      events_count = calendar[:eventlist].events.length
      subscribers_count = data_store.all_subscribers(calendar_id).length
      calendar_info_text << format(
        "%s; %s; %s; %s\n",
        calendar_id,
        calendar[:description],
        events_count,
        subscribers_count
      )
    end
    i18nkey = 'botstatus'
    i18nparams = {
      uptime: statistics[:starttime].strftime('%d.%m.%Y %H:%M:%S'),
      calendar_count: calendars.keys.length,
      calendar_info: calendar_info_text,

      bot_sent_msgs: statistics[:sent_msgs_counter],
      bot_recvd_msgs: statistics[:recvd_msgs_counter],
      bot_sent_reminders: statistics[:sent_reminders_counter],
      bot_uptime: statistics[:uptime].humanize,

      docker_image_version: docker_info[:image_version],
      docker_image_author: docker_info[:image_author],
      docker_image_build_time: docker_info[:image_build_time],
      docker_image_source_url: docker_info[:image_source_url],

      os_public_ip: os_info[:ip],
      os_uptime: os_info[:uptime],
      os_version: os_info[:version]
    }
    @message_sender.process(
      Message.new(
        i18nkey: i18nkey,
        i18nparams: i18nparams,
        id_recv: chatid,
        markup: nil
      )
    )
  end
end
