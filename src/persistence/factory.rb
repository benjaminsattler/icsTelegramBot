# frozen_string_literal: true

require 'persistence/sqlite'

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
    else
      raise NotImplementedError
    end
  end

  def get_sqlite(config)
    Sqlite.new(config['db_path'])
  end
end
