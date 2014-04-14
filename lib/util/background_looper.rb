module Ki
  class BackgroundLooper
    attr_chain :exceptions, -> { ExceptionCatcher.new }

    def run(delay=5, &block)
      @loop = true
      @mutex = Mutex.new
      @resource = ConditionVariable.new
      Thread.new do
        puts "BL: new thread"
        while @loop
          puts "LOOP"
          exceptions.catch do
            puts "Block start"
            begin
              block.call
            rescue Exception => e
              puts "Exception: #{e.message} #{e.backtrace}"
            end
            puts "Block end"
          end
          if @loop
            puts "before resource.wait"
            @resource.wait(@mutex, delay)
            puts "resource.wait ended"
          end
        end
      end
    end

    def stop
      @mutex.synchronize do
        @loop = false
        @resource.broadcast
      end
    end
  end
end