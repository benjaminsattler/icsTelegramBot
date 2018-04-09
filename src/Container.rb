class Container

    @@dependencies = {}

    def self::get(dep)
        return @@dependencies.has_key?(dep) ? @@dependencies[dep] : nil
    end

    def self::set(dep, cls)
        @@dependencies[dep] = cls
    end
end
