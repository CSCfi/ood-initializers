# Class for outputting info about an interactive app session in info.html.erb
# Usage eg. <%= CSCAppSessionInfo.log_link(self) %>
class CSCAppSessionInfo

  # Output a link to the log file for the session
  class << self
    def log_link(session)
<<-EOF
If you run into issues, please include the following log file in the support ticket: 
<a target="_blank" 
href="#{OodAppkit.files.url(path: session.staged_root.join("output.log")).to_s}">output.log
</a>
EOF
    end

    # Print resources allocated to a job
    def resources_info(session)
      msg = ""
      info = session.info
      unless session.cache_completed
        msg = <<-EOF
<b>Project:</b> #{info.accounting_id}  
<b>Partition:</b> #{info.queue_name}  
<b>Cores:</b> #{info.procs}  
<b>Memory:</b> #{info.native[:min_memory]}  
        EOF
      end
      msg
    end
  end

end
