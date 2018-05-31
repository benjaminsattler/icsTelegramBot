require 'i18n'
require 'fileutils'

class Server
  attr_reader :options
  main_instance = nil

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
    puts 'daemonizing'
    exit if fork
    Process.setsid
    exit if fork
  end

  def redirect_output(filename)
    puts "Redirecting output to #{filename}"
    FileUtils.mkdir_p(File.dirname(filename), mode: 0o755)
    FileUtils.touch filename
    File.chmod(0o644, filename)
    $stderr.reopen(filename, 'a')
    $stdout.reopen($stderr)
    $stdout.sync = $stderr.sync = true
  end

  def suppress_output
    puts 'Suppressing output'
    $stderr.reopen('/dev/null', 'a')
    $stdout.reopen('/dev/null', 'a')
    end

  def status_from_pidfile
    return :dead unless pidfile?
    begin
      pid = File.read(pidfile).to_i
      return :dead if pid == 0
      return :running unless pid == 0
    rescue Errno::EPERM, Errno::EACCES
      return :running
    rescue Errno::ENOENT
      return :dead
    end
  end

  def write_pidfile
    puts "Writing PID to #{pidfile}"
    begin
      FileUtils.mkdir_p(File.dirname(pidfile), mode: 0o755)
      FileUtils.touch pidfile
      pid = File.open(pidfile, 'w') { |f| f.write(Process.pid) }
      at_exit do
        File.delete(pidfile) if File.exist?(pidfile)
      end
    rescue Errno::EPERM, Errno::EACCES
      puts "Cannot write PIDFILE #{pidfile}: Permission denied!"
    end
  end

  def check_running
    status = status_from_pidfile
    case status
    when :dead
      begin
        File.delete(pidfile)
      rescue Errno::EPERM, Errno::EACCES
        puts "Cannot delete PIDFILE #{pidfile}: Permission error!"
        exit -2
      rescue Errno::ENOENT
      end
    when :running
      puts "Server is already running! If you think this is a mistake, please delete pidfile #{File.expand_path(pidfile)}"
      exit -1
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
    check_running if pidfile?
    daemonize if daemon? && daemon
    write_pidfile if pidfile?
    redirect_output(logfile) if logfile?
    suppress_output if !logfile? && daemon? && daemon

    puts "Starting with PID #{Process.pid}"
    puts "Loading main class #{mainClass}"

    Signal.trap('SIGUSR1') do
      puts 'Caught signal USR1'
      redirect_output(logfile) if logfile?
    end

    begin
      require mainClass
      classRef = class_from_string(mainClass)
      puts "Could not find main class #{mainClass}. Terminating..." if classRef.nil?
    rescue LoadError => e
      puts e.inspect
      puts "Could not load main class #{mainClass}. Terminating..."
      exit
    end
    puts 'Instantiating main class'
    @main_instance = classRef.new unless classRef.nil?
    @main_instance.run unless @main_instance.nil?
    0
  end
end
