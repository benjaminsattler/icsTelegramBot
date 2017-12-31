#!/usr/bin/env ruby

require 'yaml'

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
config['locale'] = ENV['LOCALE'] unless ENV['locale']

server = Server.new(config)
server.run

log("Shutdown complete.")
