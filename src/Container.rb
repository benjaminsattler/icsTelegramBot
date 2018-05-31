class Container
  @@dependencies = {}

  def self.get(dep)
    @@dependencies.key?(dep) ? @@dependencies[dep] : nil
  end

  def self.set(dep, cls)
    @@dependencies[dep] = cls
  end
end
