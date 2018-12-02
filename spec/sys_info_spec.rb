# frozen_string_literal: true

require 'sys_info'

RSpec.describe SysInfo do
  describe 'docker_info' do
    it 'returns a fully populated object' do
      sys_info = described_class.new
      actual = sys_info.docker_info
      expect(actual).to match(
        image_version: an_instance_of(String),
        image_author: an_instance_of(String),
        image_build_time: an_instance_of(String),
        image_source_url: an_instance_of(String)
      )
    end

    it 'reads correct environment variables' do
      values = {
        ICSBOT_GIT_TAG: 'test1',
        ICSBOT_BUILD_USER: 'test2',
        ICSBOT_BUILD_TIME: 'test3',
        ICSBOT_GIT_URL: 'test4'
      }
      values.each do |key, value|
        allow(ENV).to receive(:[]).with(key.to_s).and_return(value)
      end
      sys_info = described_class.new
      actual = sys_info.docker_info
      expect(actual).to match(
        image_version: values[:ICSBOT_GIT_TAG],
        image_author: values[:ICSBOT_BUILD_USER],
        image_build_time: values[:ICSBOT_BUILD_TIME],
        image_source_url: values[:ICSBOT_GIT_URL]
      )
    end
  end

  describe 'os_info' do
    it 'returns a fully populated object' do
      sys_info = described_class.new
      actual = sys_info.os_info
      expect(actual).to match(
        ip: an_instance_of(String),
        version: an_instance_of(String),
        uptime: an_instance_of(String)
      )
    end
  end
end
