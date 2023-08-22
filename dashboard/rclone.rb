require 'rclone_util'

# Dashboard initializer for filtering out Rclone remotes that do not work (invalid/expired auth/config).

class RcloneUtil
  class << self
    # Check if remote can be accessed (responds to directory list request).
    def valid?(remote)
      # This gives a total max duration of 6s (2s * 3 attempts)
      _, _, s = rclone(
        'lsd',                 "#{remote}:",
        '--contimeout',        '2s',
        '--timeout',           '2s',
        '--low-level-retries', '1',
        '--retries',           '1'
      )
      s.success?
    rescue StandardError
      false
    end

    def extra_conf
      @@extra_env ||= begin
          extra_conf = File.join(Dir.home, ".config/rclone/ood.conf")
          o, e, s = rclone("config", "dump", env: { "RCLONE_CONFIG" => extra_conf })
          return {} unless s.success?

          remotes = JSON.parse(o)

          # Combine config into a single Hash where keys and values are e.g.
          # RCLONE_CONFIG_MYREMOTE_TYPE: "s3"
          remotes.map do |remote_name, remote|
            remote.transform_keys do |key|
              "RCLONE_CONFIG_#{remote_name.upcase}_#{key.upcase}"
            end
          end.reduce(&:merge) || {} # reduce on empty array returns nil
        end
    rescue => e
      Rails.logger.error("Could not read extra Rclone configuration: #{e.message}")
      {}
    end

    def rclone(*args, env: extra_conf, **kwargs)
      # Using Open3.capture3 will use Open3Extensions.capture3 from OOD, which logs the
      # sensitive env vars. Access singleton method directly instead.
      Open3.singleton_method(:capture3).call(env, rclone_cmd, *args, **kwargs)
    end

    def rclone_popen(*args, stdin_data: nil, env: extra_conf, **kwargs, &block)
      # Use -q to suppress message about config file not existing
      # need it here as we check err.present?
      Open3.popen3(env, rclone_cmd, "--quiet", *args) do |i, o, e, t|
        if stdin_data
          i.write(stdin_data)
        end
        i.close

        err_reader = Thread.new { e.read }

        yield o

        o.close
        exit_status = t.value
        err = err_reader.value.to_s.strip
        if err.present? || !exit_status.success?
          raise RcloneError.new(exit_status.exitstatus), "Rclone exited with status #{exit_status.exitstatus}\n#{err}"
        end
      end
    end
  end
end

# Double wrapped after_initialize to ensure this runs after rclone.rb in upstream since
# /etc/ood/config/... initializers always run after /var/www/ood/... ones.
Rails.application.config.after_initialize do
  Rails.application.config.after_initialize do
    next unless Configuration.remote_files_enabled?

    # This part runs twice (before and after /var/www/ood rclone.rb initializer), but that is fine,
    # path list empty first time.
    OodFilesApp.candidate_favorite_paths.tap do |paths|
      remotes = paths.filter(&:remote?).map(&:filesystem)

      valid_remotes = {}
      mutex = Mutex.new

      # Query remotes in parallel
      remotes.map do |remote|
        Thread.new do
          valid = RcloneUtil.valid?(remote)
          mutex.synchronize do
            valid_remotes[remote] = valid
          end
        end
      end.each(&:join)

      paths.filter! { |p| !p.remote? || valid_remotes[p.filesystem] }
    end
  rescue StandardError => e
    Rails.logger.error("Cannot add rclone favorite paths because #{e.message}")
  end
end
