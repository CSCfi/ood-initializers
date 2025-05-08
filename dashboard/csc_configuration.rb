module CSCConfiguration
  class << self
    def release_name
      @@release ||= begin
          version = File.read("/etc/ood/config/CSC_OOD_RELEASE")
          "Release #{version}"
        rescue
          "develop"
        end
    end

    def reset_favorite_paths
      OodFilesApp.candidate_favorite_paths.tap do |paths|
        paths.clear
        # Add each user's project projappl and scratch directories to the
        # file app as links.
        projects = User.new.groups.map(&:name)
        # Assuming that the directories are named like the projects.
        paths.concat projects.filter_map { |p| FavoritePath.new(File.realpath("/projappl/#{p}")) if File.exist?("/projappl/#{p}") }
        paths.concat projects.filter_map { |p| FavoritePath.new(File.realpath("/scratch/#{p}")) if File.exist?("/scratch/#{p}") }
      end
    end

    # Helper function to generate dashboard.yml configurations for custom dashboard pages.
    def custom_page(name, widget: nil, app: nil, group: nil, indent: 2)
      # Hide if app does not exist or user does not have access to it.
      return "" if app && !File.readable?(File.join("/var/www/ood/apps/sys", app))
      # Hide if user does not belong to group.
      return "" if group && !OodSupport::User.new.groups.map(&:name).include?(group)
      widget = widget || name
      entry = Hash[name, {
        rows: [
          {
            columns: [
              { widgets: ["shared_style", widget] }
            ]
          }
        ]
      }].deep_stringify_keys
      Psych.dump(entry).gsub(/\A---\n/, '').gsub(/^/, " "*indent)
    end

    # Helper function for submit.yml.erb for validating that the requested job duration is allowed
    def validate_job_length(requested, partition_name="")
      max_length = ENV["OOD_CSC_MAX_JOB_LENGTH"]
      skip_check = ENV.fetch("OOD_CSC_SKIP_JOB_LENGTH_CHECK_PARTITIONS", "").split(",").include?(partition_name)
      if requested.blank? || max_length.blank? || skip_check
        return
      end
      time_regex = Regexp.new(/^(?:(?:(?:(?<d>\d+)-)?(?<h>\d+):)?(?<m>\d+):)?(?<s>\d+)$/)
      req_match = time_regex.match(requested)
      conf_match = time_regex.match(max_length)
      req_seconds = req_match[:d].to_i * 24 * 60 * 60 +
                    req_match[:h].to_i * 60 * 60 +
                    req_match[:m].to_i * 60 +
                    req_match[:s].to_i
      conf_max_seconds = conf_match[:d].to_i * 24 * 60 * 60 +
                    conf_match[:h].to_i * 60 * 60 +
                    conf_match[:m].to_i * 60 +
                    conf_match[:s].to_i
      if req_seconds > conf_max_seconds
        raise "Requested job length exceeds maximum allowed (#{max_length})"
      end
    end
  end
end
