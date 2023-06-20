require 'open3'
require 'pathname'

# Class for outputting info about an interactive app session in info.html.erb
# Usage eg. <%= CSCAppSessionInfo.new(self).log_link %>
class CSCAppSessionInfo

  LOG_LINK_ERB = <<-EOF
<p>
  If you run into issues, please include the following log file in the support ticket:
  <a
    target="_blank"
    href="<%= OodAppkit.files.url(path: session.output_file) -%>"
  >
  <%= File.basename(session.output_file) -%>
  </a>
</p>
EOF

  JOB_INFO_ERB = <<-EOF
<p>
  <% if accounting_id.present? %>
    <b>Project:</b> <%= accounting_id %>
    <br>
  <% end %>
  <% if queue_name.present? %>
    <b>Partition:</b> <%= queue_name %>
    <br>
  <% end %>
  <% if procs.present? %>
    <b>Cores:</b> <%= procs %>
    <br>
  <% end %>
  <% if memory.present? %>
    <b>Memory:</b> <%= memory %>
    <br>
  <% end %>
  <% if nvme.present? %>
    <b>Local disk:</b> <%= nvme %> GB
    <br>
  <% end %>
  <% if gpus.present? %>
    <b>GPUs (<%= gpus[:type].upcase -%>):</b> <%= gpus[:amount] %>
    <br>
  <% end %>
  <% if modules.present? %>
    <b>Module<%= "s" if modules.length > 1 %>:</b> <%= modules.join(", ") %>
    <br>
  <% end %>
</p>
EOF

  SEFF_STATS_ERB = <<-EOF
<% if session.cache_completed && !job_id.nil? %>
<div>
  <button
    class="btn btn-primary"
    type="button"
    data-toggle="collapse"
    data-target="#seff_stats_<%= job_id -%>"
    aria-expanded="false"
    aria-controls="seff_stats_<%= job_id -%>"
    id="toggle_stats_<%= job_id -%>"
  >
    Show job stats
  </button>
  <div class="collapse" id="seff_stats_<%= job_id -%>">
    <p><%= seff_output.lines.join("<br>") %></p>
  </div>
  <script>
    $("#toggle_stats_<%= job_id -%>").click(function() {
      $(this).text(function(i, old_text) {
        return old_text.includes("Show") ? "Hide job stats" : "Show job stats"
      });
    });
  </script>
</div>
<% end %>
EOF

  attr_reader :session

  delegate :info, :cache_completed, to: :session
  delegate :accounting_id, :queue_name, :procs, to: :info

  def initialize(session)
    @session = session
  end

  # Link to log file for session
  def log_link
    render_erb(LOG_LINK_ERB)
  end

  # Job information (project, partition, resources, etc.)
  def job_info
    render_erb(JOB_INFO_ERB) unless cache_completed
  end

  # Stats from seff for the job
  def seff_stats
    render_erb(SEFF_STATS_ERB) if cache_completed
  end

  # Reason why the job exited
  def exit_reason
    get_exit_reason if cache_completed
  end

  def render_erb(template)
    ERB.new(template, nil, "-").result(binding)
  rescue => e
    Rails.logger.error("Error rendering template for app card: #{e}\n#{e.backtrace.take(10)}")
    ""
  end

  def memory
    info.native&.fetch(:min_memory, nil)
  end

  def gres
    info.native&.fetch(:gres, nil)
  end

  def nvme
    match = gres&.match(/nvme:(\d+)/)
    match[1] unless match.nil?
  end

  def gpus
    match = gres&.match(/gpu:(?<type>.+):(?<amount>\d+)/)
    if !match.nil?
      return {:type => match[:type], :amount => match[:amount]}
    end
  end

  def modules
    @modules ||= get_modules.split(" ")
  end

  def job_id
    session.instance_variable_get(:@job_id)
  end

  def get_modules
    context = File.read(session.user_defined_context_file)
    options = JSON.parse(context)
    # VSCode/RStudio
    if options.has_key?("modules")
      options.fetch("modules", "")
      # Jupyter
    elsif options.has_key?("python_module")
      modules = options.fetch("python_module", "")
      if modules == "Custom"
        modules = options.fetch("custom_module", "")
      end
      modules
    else
      ""
    end
  rescue => e
    # Fail silently (user defined context doesnt exist or is invalid)
    ""
  end

  def seff_output
    seff_cache_file = session.staged_root.join("seff_cache")
    cached_or_else(seff_cache_file) do
      o, e, s = Open3.capture3("seff", job_id)
      if s.success?
        o
      else
        "Error getting job efficiency statistics: #{e}"
      end
    rescue => e
      Rails.logger.error("Error getting job efficiency statistics: #{e}")
      ""
    end
  end

  # Get the cached exit reason or parse from log file if cached doesn't exist
  def get_exit_reason
    log_file = session.output_file
    cached_reason_file = session.staged_root.join("job_exit_reason")
    cached_or_else(cached_reason_file) do
      find_exit_reason(log_file)
    end
  end

  # Parse the last lines of log_file and find common exit reasons
  def find_exit_reason(log_file)
    if File.exists?(log_file) && File.readable?(log_file)
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

  # Read the contents of a file or write contents returned by block if it doesn't exist
  def cached_or_else(file, &block)
    if File.exists?(file) && File.readable?(file)
      File.read(file)
    else
      content = yield
      dir = File.dirname(file)
      if !File.directory?(dir)
        FileUtils.mkdir_p(dir)
      end
      content.tap do |c|
        File.open(file, 'w') { |file| file.write(content) }
      end
    end
  rescue IOError
    Rails.logger.error("Error reading or writing cache file #{file} for app card: #{e}")
    ""
  end

  # Instance methods for backwards compatibility
  class << self
    def log_link(session)
      self.new(session).log_link
    end

    def job_info(session)
      self.new(session).job_info
    end

    def exit_reason(session)
      self.new(session).exit_reason
    end

    def seff_stats(session)
      self.new(session).seff_stats
    end
  end
end
