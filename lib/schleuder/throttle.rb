module Schleuder
  class Throttle
    def self.cleanup
      pid_files.each do |symlink|
        if ! File.exist?(File.readlink(symlink))
          File.delete(symlink)
        end
      end
    end

    def self.register
      cleanup
      if pid_files.size < Conf.throttle_max_processes
        File.symlink "/proc/#{Process.pid}", pid_file
      else
        false
      end
    end

    def self.unregister
      if File.exist?(pid_file)
        File.delete pid_file
      end
    end

    def self.pid_file
      File.join(RUN_STATE_DIR, Process.pid.to_s)
    end

    def self.pid_files
      Dir.glob(File.join(RUN_STATE_DIR, '*'))
    end

  end
end
