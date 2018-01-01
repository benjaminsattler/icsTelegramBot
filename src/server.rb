require 'i18n'
require 'fileutils'

class Server

    attr_reader :options
    def initialize(options)
        @options = options
    end

    def pidfile?
        !@options[:pid].nil?
    end

    def pidfile
        @options[:pid]
    end

    def logfile?
        !@options[:log].nil?
    end

    def logfile
        @options[:log]
    end

    def daemon?
        !@options[:daemon].nil?
    end

    def daemon
        @options[:daemon]
    end

    def mainClass?
        !@options[:main].nil?
    end

    def mainClass
        @options[:main]
    end
    
    def daemonize
        puts "daemonizing"
        exit if fork
        Process.setsid
        exit if fork
    end
    
    def redirect_output(filename)
        FileUtils.mkdir_p(File.dirname(filename), :mode => 0755)
        FileUtils.touch filename
        File.chmod(0644, filename)
        $stderr.reopen(filename, 'a')
        $stdout.reopen($stderr)
        $stdout.sync = $stderr.sync = true
    end

    def suppress_output
        $stderr.reopen('/dev/null', 'a')
        $stdout.reopen('/dev/null', 'a')
      end

    def status_from_pidfile
        return :dead unless self.pidfile?
        begin
            pid = File.read(self.pidfile).to_i
            return :dead if pid == 0
            return :running unless pid == 0
        rescue Errno::EPERM, Errno::EACCES
            return :running
        rescue Errno::ENOENT
            return :dead
        end
    end

    def write_pidfile
        begin
            FileUtils.mkdir_p(File.dirname(self.pidfile), :mode => 0755)
            FileUtils.touch self.pidfile
            pid = File.open(self.pidfile, 'w') { |f| f.write(Process.pid) }
            at_exit {
               File.delete(self.pidfile) if File.exists?(self.pidfile)
            }
        rescue Errno::EPERM, Errno::EACCES
            puts "Cannot write PIDFILE #{self.pidfile}: Permission denied!"
            
        end
    end

    def check_running
        status = self.status_from_pidfile
        case status
        when :dead
            begin
                File.delete(self.pidfile)
            rescue Errno::EPERM, Errno::EACCES
                puts "Cannot delete PIDFILE #{self.pidfile}: Permission error!"
                exit
            rescue Errno::ENOENT
            end
        when :running
            puts "Server is already running! If you think this is a mistake, please delete pidfile #{File.expand_path(self.pidfile)}"
            exit
        end
    end

    def class_from_string(str)
        str.split('::').inject(Object) do |mod, class_name|
            mod.const_get(class_name)
        end
    rescue NameError
        nil?
    end

    def start        
        self.check_running if self.pidfile?
        self.daemonize if self.daemon? and self.daemon
        self.write_pidfile if self.pidfile?
        self.redirect_output(self.logfile) if self.logfile?
        self.suppress_output if not self.logfile? and self.daemon? and self.daemon
    
        require self.mainClass

        classRef = self.class_from_string(self.mainClass)
        classRef.new.run unless classRef.nil?
        puts "Could not load main class #{self.mainClass}. Terminating..." if classRef.nil?
    end
end
