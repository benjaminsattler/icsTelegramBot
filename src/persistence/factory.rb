# frozen_string_literal: true

require 'persistence/sqlite'
require 'persistence/mysql'

# This class will return a persistence instance
# based on the configuration file
class Factory
  def initialize(config_map)
    @config_map = config_map
  end

  def get(persistence)
    case persistence
    when 'sqlite'
      sqlite
    when 'mysql'
      mysql
    else
      raise NotImplementedError
    end
  end

  def sqlite
    Sqlite.new(@config_map.get('sqlite.db_path'))
  end

  def mysql
    Mysql.new(
      @config_map.get('mysql.host'),
      @config_map.get('mysql.port'),
      @config_map.get('mysql.username'),
      @config_map.get('mysql.password'),
      @config_map.get('mysql.database')
    )
  end
end
