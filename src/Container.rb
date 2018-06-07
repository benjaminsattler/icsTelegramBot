# frozen_string_literal: true

# rubocop:disable Style/ClassVars
##
# This class stores references to the
# most frequently used objects and
# makes them available globally.
# (Use with caution!)
class Container
  @@dependencies = {}

  def self.get(dep)
    @@dependencies.key?(dep) ? @@dependencies[dep] : nil
  end

  def self.set(dep, cls)
    @@dependencies[dep] = cls
  end
end
# rubocop:enable Style/ClassVars
