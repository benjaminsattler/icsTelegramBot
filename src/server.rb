# frozen_string_literal: true

require 'i18n'
require 'fileutils'

##
# This class configures the runtime environment of the
# main thread.
class Server
  attr_reader :options
  @main_instance = nil

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

  def main_class?
    !@options[:main].nil?
  end

  def main_class
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
      return :dead if pid.zero?
      return :running unless pid.zero?
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
      File.open(pidfile, 'w') { |f| f.write(Process.pid) }
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
        exit(-2)
      rescue Errno::ENOENT
        nil
      end
    when :running
      puts 'Server is already running!'\
          'If you think this is a mistake,'\
           "please delete pidfile #{File.expand_path(pidfile)}"
      exit(-1)
    end
  end

  def class_from_string(str)
    str.split('::').inject(Object) do |mod, class_name|
      mod.const_get(class_name)
    end
  rescue NameError
    nil
  end

  def to_camel_case(str)
    str = str.gsub(/(.)([A-Z])/, '\1_\2')
    str.downcase
  end

  def start
    check_running if pidfile?
    daemonize if daemon? && daemon
    write_pidfile if pidfile?
    redirect_output(logfile) if logfile?
    suppress_output if !logfile? && daemon? && daemon

    main_class_file = to_camel_case(main_class)
    puts "Starting with PID #{Process.pid}"
    puts "Loading main class #{main_class} from #{main_class_file}"

    Signal.trap('SIGUSR1') do
      puts 'Caught signal USR1'
      redirect_output(logfile) if logfile?
    end

    begin
      require main_class_file
      class_ref = class_from_string(main_class)
      if class_ref.nil?
        puts "Could not find main class #{main_class}. Terminating..."
      end
    rescue LoadError => e
      puts e.inspect
      puts "Could not load main class #{main_class}. Terminating..."
      exit
    end
    puts 'Instantiating main class'
    @main_instance = class_ref.new unless class_ref.nil?
    @main_instance&.run
    0
  end
end
