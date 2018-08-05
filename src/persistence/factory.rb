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
      get_sqlite(@config_map['sqlite'])
    when 'mysql'
      get_mysql(@config_map['mysql'])
    else
      raise NotImplementedError
    end
  end

  def get_sqlite(config)
    Sqlite.new(config['db_path'])
  end

  def get_mysql(config)
    Mysql.new(
      config['host'],
      config['port'],
      config['username'],
      config['password'],
      config['database']
    )
  end
end
