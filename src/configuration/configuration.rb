# frozen_string_literal: true

##
# This class represents the base class for configurations
class Configuration
  def get(_name)
    raise NotImplementedError
  end
end
