# frozen_string_literal: true

require_relative 'configuration.rb'
require 'yaml'

##
# This class loads app configuration from a yaml file.
class YamlFileConfiguration < Configuration
  attr_reader :config_filename
  def initialize(filename)
    @config_filename = filename
  end

  def load_config_from_file(filename)
    YAML.load_file(filename, 'r')
  end

  def get(name)
    @config = load_config_from_file(@config_filename) if @config.nil?
    fragments = name.split(/\./)
    needle = @config
    while !fragments.nil? && !fragments.empty? && needle.respond_to?(:[])
      needle = needle[fragments.slice!(0)]
    end
    needle
  end
end
