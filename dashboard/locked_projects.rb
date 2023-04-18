module LockedProjects
  Project = Struct.new(:user, :project, :state, :grace_time_end) do

    def locked
      self.state == "locked"
    end

    def will_be_locked
      self.state == "delayed" || self.state == "grace"
    end
  end

  class << self
    # List of projects the user belongs to
    def filtered
      @filtered ||= begin
          user = Etc.getpwuid.name
          all.filter { |p| p.user == user }
        end
    end

    def locked
      @locked ||= filtered.filter(&:locked)
    end

    def will_be_locked
      @will_be_locked ||= filtered.filter(&:will_be_locked)
    end

    private

    def all
      # File is colon separated, <user>:<project>:<state>:[grace_time_end]
      # grace_time_end is only defined for state "grace".
      File.read(locked_projects_file).strip.lines.map { |l| Project.new(*l.split(":").map(&:strip)) }
    rescue => e
      Rails.logger.error("Could not read list of locked projects: #{e}")
      []
    end

    def locked_projects_file
      "/var/lib/acco/locked_projects_map.txt"
    end
  end
end
