require "sys_router"

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

    def enable_flash?
      ENV.fetch("OOD_CSC_ENABLE_FLASH", "false") == "true"
    end

    def reset_favorite_paths
      OodFilesApp.candidate_favorite_paths.tap do |paths|
        paths.clear
        # Add each user's project projappl and scratch directories to the
        # file app as links.
        projects = User.new.groups.map(&:name)
        # Assuming that the directories are named like the projects.
        paths.concat projects.filter_map { |p| FavoritePath.new("/projappl/#{p}") if File.exist?("/projappl/#{p}") }
        paths.concat projects.filter_map { |p| FavoritePath.new("/scratch/#{p}") if File.exist?("/scratch/#{p}") }
        paths.concat projects.filter_map { |p| FavoritePath.new("/flash/#{p}") if  File.exist?("/flash/#{p}") } if enable_flash?
      end
    end

    # Helper function to generate dashboard.yml configurations for custom dashboard pages.
    def custom_page(name, widget: nil, app: nil, group: nil, indent: 2)
      # Hide if app does not exist or user does not have access to it.
      return "" if app && !File.readable?("#{SysRouter.base_path}/#{app}")
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

    def industry_user?
      projects = User.new.groups.map(&:name)
      industry_projects = File.read("/opt/csc/industry_projects.txt").lines.map(&:strip)
      industry_user = projects.any? { |p| industry_projects.include?(p) }
    rescue => e
      false
    end
  end
end
