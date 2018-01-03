require 'log'

class Watchdog

    @watchThreads = nil
    @watchInterval = nil
    @watchThread = nil
    @stop = false
    @stopTimeout = nil

    def initialize
        @watchThreads = Array.new
        @watchInterval = 1
        @stopTimeout = 15
    end

    def stop
        @watchThread[:stop] = true
        @watchThread.join(@stopTimeout * (@watchThreads.length + 1))
        log("Watchthread terminating...")
    end

    def randomKill
        if Random.new.rand < 0.1 then
            which = Random.new.rand(0..@watchThreads.length)
            @watchThreads[0][:handle].kill
        end
    end

    def watch(thread_list)
        @watchThreads = thread_list.each { |thread_desc|
            thread_desc[:handle] = Thread.new {sleep()}
            thread_desc[:handle].kill
        }
        
        @watchThread = Thread.new(@watchThreads, @stopTimeout) do |threads, stopTimeout|
            Thread.current[:stop] = false
            stop = false
            while(not stop) do
                threads.each do |thread_desc|
                    unless thread_desc[:handle].alive? then
                        log("(Re)starting thread #{thread_desc[:name]}")
                        thread_desc[:handle] = Thread.new &thread_desc[:thr]
                    end
                end
                if Thread.current[:stop] then
                    threads.each do |thread_desc|
                        log("Stopping thread #{thread_desc[:name]} (Timeout #{stopTimeout} seconds)")
                        thread_desc[:handle][:stop] = true
                        thread_desc[:handle].join(stopTimeout)
                    end 
                    Thread.current[:stop] = false
                    stop = true
                else
                    sleep @watchInterval
                end
            end
        end
    end
end
