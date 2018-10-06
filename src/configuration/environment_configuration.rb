# frozen_string_literal: true

require_relative 'configuration.rb'
require 'yaml'

##
# This class loads app configuration from a yaml file.
class EnvironmentConfiguration < Configuration
  def get(name)
    sane_name = name.tr('.', '_')
    ENV[sane_name]
  end
end
