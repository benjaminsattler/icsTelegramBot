# frozen_string_literal: true

require 'log'

##
# This class represents the watchdog thread, which
# tries to restart killed threads until it is ended
# itself.
class Watchdog
  @watch_threads = nil
  @watch_interval = nil
  @watch_thread = nil
  @stop = false
  @timeout = nil

  def initialize
    @watch_threads = []
    @watch_interval = 1
    @timeout = 15
  end

  def stop
    @watch_thread[:stop] = true
    @watch_thread.join(@timeout * (@watch_threads.length + 1))
    log('Watchthread terminating...')
  end

  def random_kill
    return if Random.new.rand >= 0.1

    which = Random.new.rand(0..@watch_threads.length - 1)
    log "Killing thread #{@watch_threads[which][:name]}"
    @watch_threads[which][:handle].kill
  end

  def watch(thread_list)
    @watch_threads = thread_list.each do |thread_desc|
      thread_desc[:handle] = Thread.new { sleep }
      thread_desc[:handle].kill
    end

    @watch_thread = Thread.new(@watch_threads, @timeout) do |threads, timeout|
      Thread.current[:stop] = false
      stop = false
      until stop
        threads.each do |thread_desc|
          unless thread_desc[:handle].alive?
            log("(Re)starting thread #{thread_desc[:name]}")
            thread_desc[:handle] = Thread.new(&thread_desc[:thr])
          end
        end
        if Thread.current[:stop]
          threads.each do |thread_desc|
            log("Stopping thread #{thread_desc[:name]}"\
                " (Timeout #{timeout} seconds)")
            thread_desc[:handle][:stop] = true
            thread_desc[:handle].join(timeout)
            thread_desc[:handle].exit if thread_desc[:handle].alive?
          end
          Thread.current[:stop] = false
          stop = true
        else
          sleep @watch_interval
        end
      end
    end
    @watch_thread
  end
end
