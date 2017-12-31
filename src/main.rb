#!/usr/bin/env ruby

require 'yaml'
require 'i18n'

require 'server'
require 'log'

defaultConfigFile = File.join File.dirname(__FILE__), '..', 'config', 'conf.yml'

config = nil

def loadConfig(configFile)
    YAML.load_file(configFile)
end

def getCommandlineArgument(argname)
    args = {}
    ARGV.each do |arg|
        matcher = /^([^=]+)=(.+)$/.match(arg)
        if (matcher) then
            args[matcher[1]] = matcher[2]
        else
            args[arg] = true
        end
    end
    args[argname]
end
 
configFilename = getCommandlineArgument('--config').nil? ? defaultConfigFile : getCommandlineArgument('--config')
config = loadConfig(configFilename)
locale = getCommandlineArgument('--lang').to_sym unless getCommandlineArgument('--lang').nil?

Logger.setLogfile(File.join(File.dirname(__FILE__), '..', config['log_file']))

I18n.load_path = Dir[File.join(File.dirname(__FILE__), '..', 'lang', '*.yml')]
I18n.backend.load_translations
I18n.default_locale = :de
I18n.locale = locale unless locale.nil?

server = Server.new(config)

server.run

log("Shutdown complete.")
