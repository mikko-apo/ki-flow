module Ki
  module ActionBase

    class CiLogger
      include HashLog
    end

    attr_chain :action_log_dir, :require
    attr_chain :action_log_file, -> { action_log_dir.action_log }
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

    def collect_logs_and_save(name, &block)
      log_root = nil
      background_write = BackgroundLooper.new
      begin
        logger.log(name) do |l|
          log_root = l
          BackgroundLooper.new do
            write_log_file(log_root)
          end
          exceptions.catch(name) do
            block.call(log_root)
          end
          after("cleanup child processes") do
            HashLogShell.cleanup
          end
          if after_actions.size > 0
            go("after") do
              after_actions.each do |name, block|
                go(name) do
                  block.call
                end
              end
            end
          end
          @exceptions.check
        end
      ensure
        background_write.stop
        write_log_file(log_root)
      end
    end

    def write_log_file(log_root)
      puts "Logging to #{action_log_file.path}"
      collect_files_from_log_dir(log_root)
      File.safe_write(action_log_file.path, JSON.pretty_generate(log_root.dup))
    end

    def collect_files_from_log_dir(log_root)
      files = Dir.glob(action_log_dir.path("**/*")) - [action_log_file.path]
      files.map! do |path|
        short_path = path[action_log_dir.path.size..-1]
        if short_path.start_with?("/")
          short_path = short_path[1..-1]
        end
        short_path
      end
      log_root.delete("files")
      if files.size > 0
        log_root["files"]=files
      end
    end

    def new_sh
      HashLogShell.new.root_log(logger)
    end
  end
end
