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
