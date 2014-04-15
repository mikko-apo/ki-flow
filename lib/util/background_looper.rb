module Ki
  class BackgroundLooper
    attr_chain :exceptions, -> { ExceptionCatcher.new }

    def run(delay=20, &block)
      @loop = true
      @mutex = Mutex.new
      @resource = ConditionVariable.new
      Thread.new do
        exceptions.catch do
          while @loop
            block.call
            if @loop
              @mutex.synchronize do
                @resource.wait(@mutex, delay)
              end
            end
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