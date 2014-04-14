module Ki
  module ActionBase

    class CiLogger
      include HashLog
    end

    attr_chain :logger, -> { CiLogger.new }
    attr_chain :exceptions, -> { ExceptionCatcher.new }
    attr_chain :after_actions, -> { [] }

    def in_parallel(name, list, &block)
      logger.log(name) do |root|
        scheduler = Ki::Ci::RealtimeTaskScheduler.new
        list.each do |item|
          scheduler.add_task(item) do
            logger.set_hash_log_root_for_thread(root)
            logger.log(item) do
              block.call(item)
            end
          end
        end
        scheduler.run_all_tasks
      end
    end

    def go(name, &block)
      exceptions.catch(name) do
        logger.log(name) do |log|
          block.call(log)
        end
      end
    end

    def in_thread(name, &block)
      root = logger.hash_log_current
      Thread.new do
        logger.set_hash_log_root_for_thread(root)
        go(name, &block)
      end
    end

    def after(name, &block)
      after_actions << [name, block]
    end

    def collect_logs_and_save(file, name, &block)
      log_root = nil
      begin
        logger.log(name) do |l|
          log_root = l
          @exceptions.catch(name) do
            block.call(log_root)
          end
          if at_exists.size > 0
          go("after") do
            after_actions.each do |name, block|
              go(name) do
                block.call
              end
            end
          end
          end
          go("cleanup child processes") do
            HashLogShell.cleanup
          end
          @exceptions.check
        end
      ensure
        if file
          puts "Logging to #{file}"
          File.safe_write(file, JSON.pretty_generate(log_root))
        else
          puts JSON.pretty_generate(log_root)
        end
      end
    end

    def new_sh
      HashLogShell.new.root_log(logger)
    end
  end
end
