require 'open3'

# Class for outputting info about an interactive app session in info.html.erb
# Usage eg. <%= CSCAppSessionInfo.log_link(self) %>
class CSCAppSessionInfo

  # Output a link to the log file for the session
  class << self
    def log_link(session)
      <<-EOF
If you run into issues, please include the following log file in the support ticket: 
<a target="_blank" 
href="#{OodAppkit.files.url(path: session.output_file)}">#{File.basename(session.output_file)}
</a>
      EOF
    end

    # Print job information
    def job_info(session)
      msg = ""
      unless session.cache_completed
        info = session.info
        project = "<b>Project:</b> #{info.accounting_id}  \n" unless info.accounting_id == nil
        partition = "<b>Partition:</b> #{info.queue_name}  \n" unless info.queue_name == nil
        cores = "<b>Cores:</b> #{info.procs}  \n" unless info.procs == nil
        memory = "<b>Memory:</b> #{info.native[:min_memory]}  \n" unless (info.native == nil || !info.native.key?(:min_memory))

        # NVME and GPUs are only available by parsing native[:gres]
        if info.native != nil && info.native.key?(:gres)
          nvme = begin
                   nvme_match = info.native[:gres].match(/nvme:(\d+)/)
                   nvme_match[1] unless nvme_match == nil
                 end
          gpus = begin
                   gpu_match = info.native[:gres].match(/gpu:(.+):(\d+)/)
                   if gpu_match != nil
                     gpu_type = gpu_match[1]
                     gpus = gpu_match[2]
                     {:type => gpu_type, :amount => gpus}
                   end
                 end
          nvme_string = "<b>Local disk:</b> #{nvme} GB  \n" unless nvme == nil
          gpu_string = "<b>GPUs (#{gpus[:type]}):</b> #{gpus[:amount]}  \n" if (gpus != nil && gpus[:amount] != "0")
        end
        msg = "#{project}#{partition}#{cores}#{memory}#{nvme_string}#{gpu_string}"
      end
      msg
    end

    # Returns the reason why a job exited
    def exit_reason(session)
      sanitizer ||= Rails::Html::FullSanitizer.new
      if session.cache_completed
        sanitizer.sanitize(get_exit_reason(session))
      else
        ""
      end
    end

    private

    # Get the cached exit reason or parse from log file if cached doesn't exist
    def get_exit_reason(session)
      log_file = session.output_file
      cached_reason_file = session.staged_root.join("job_exit_reason")
      if File.exists?(cached_reason_file)
        File.open(cached_reason_file).read
      else
        reason = find_exit_reason(log_file)
        File.open(cached_reason_file, 'w') { |file| file.write(reason) }
        reason
      end
    rescue IOError
      ""
    end

    # Parse the last lines of log_file and find common exit reasons
    def find_exit_reason(log_file)
      if File.exists?(log_file)
        lines, _ = Open3.capture2("tail", "-n 9", log_file.to_s)
        # Slurm time limit
        if lines.include?("DUE TO TIME LIMIT")
          "Job exceeded time limit"
          # Slurm memory limit
        elsif lines.include?("Exceeded job memory limit")
          "Job exceeded memory limit"
          # Cancel via scancel
        elsif lines.include?("CANCELLED AT")
          "Job was cancelled"
          # App didn't launch in the time specified in after.sh
        elsif lines.include?("Timed out waiting")
          "Job took too long to start"
        else
          "Job cancelled for unknown reason"
        end
      else
        "Log file for job does not exist"
      end
    end
  end

end
