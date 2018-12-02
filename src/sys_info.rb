# frozen_string_literal: true

require 'json'

##
# This class returns system information
class SysInfo
  def docker_info
    {
      image_version: ENV['ICSBOT_GIT_TAG'],
      image_author: ENV['ICSBOT_BUILD_USER'],
      image_build_time: ENV['ICSBOT_BUILD_TIME'],
      image_source_url: ENV['ICSBOT_GIT_URL']
    }
  end

  def os_info
    begin
      version = `uname -a`.chomp
    rescue StandardError
      version = nil
    end
    begin
      uptime = `uptime`.chomp
    rescue StandardError
      uptime = nil
    end
    {
      ip: public_ip,
      version: version,
      uptime: uptime
    }
  end

  def public_ip
    begin
      raw = `wget -O - -q -T 5 https://api.ipify.org?format=json`.chomp
      parsed = JSON.parse raw
    rescue StandardError
      parsed = { 'ip' => nil }
    end
    parsed['ip']
  end
end
