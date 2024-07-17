# Note: When editing this file, changes will only take effect
# AFTER the PUNs are refreshed.
require 'timeout'
# Add quota and balance file path for the user
ENV["OOD_CSC_QUOTA_PATH"] = "/tmp/#{ENV["USER"]}_ood_quotas.json"
ENV["OOD_CSC_BALANCE_PATH"] = "/tmp/#{ENV["USER"]}_ood_balance.json"

Rails.application.config.after_initialize do
  # Require the smart attributes for batch connect forms
  require "smart_attributes"
  require "#{ENV["CSC_OOD_DEPS_PATH"]}/util/attributes/csc_smart_attributes"

  Rails.logger.info("Running dashboard initializer for user #{`whoami`.strip}")

  CSCConfiguration.reset_favorite_paths
  # Based on https://discourse.osc.edu/t/set-order-of-interactive-apps-menu-items/1271
  # Sort param added for 2.1 compatibility
  def OodAppGroup.groups_for(apps: [], group_by: :category, nav_limit: nil, sort: true)
    groups = apps.group_by { |app|
      app.respond_to?(group_by) ? app.send(group_by) : app.metadata[group_by]
    }.map { |k, v|
      OodAppGroup.new(title: k, apps: sort ? v.sort_by { |a| a.title } : v, nav_limit: nav_limit)
    }

    groups = sort ? groups.sort_by { |g| [g.title.nil? ? 1 : 0, g.title] } : groups

    if group_by.to_s == "subcategory" && sort
      # Sort Course environments subcategory to end
      groups.sort_by { |g| g.title == "Course environments" ? 1 : 0 }
    else
      groups
    end
  end

  # Update quota and balance JSON files in tmp, set BU limit to 5%
  LustreQuota.write_quota_warning_json(ENV["OOD_CSC_QUOTA_PATH"])

  # Use OODs default quota warnings for home directory only
  # Other quota warnings will be visible in the widget and use env vars OOD_CSC_*
  begin
    ENV["OOD_QUOTA_PATH"] = "/tmp/#{ENV["USER"]}_ood_home_quota.json"
    # Read all quotas and filter it to have only home dir
    quota_file = File.read(ENV["OOD_CSC_QUOTA_PATH"])
    home_quotas = JSON.parse(quota_file)
    home_quotas["quotas"] = home_quotas["quotas"].filter { |quota| quota["path"] == Dir.home }
    File.write(ENV["OOD_QUOTA_PATH"], home_quotas.to_json)
  rescue => e
    Rails.logger.error("Failed to create home directory quota file: #{e.message}")
  end
end

def checkWithTimeout(path,timer)
  begin
    status = Timeout::timeout(timer) {
    File.exist?(path)
  }
  rescue
    return true 
  end
  return status
end  


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
        to = 1 
        paths.concat projects.filter_map { |p| FavoritePath.new("/projappl/#{p}") if File.exist?("/projappl/#{p}") }
        paths.concat projects.filter_map { |p| FavoritePath.new("/scratch/#{p}") if File.exist?("/scratch/#{p}") }
        paths.concat projects.filter_map { |p| FavoritePath.new("/flash/#{p}") if  checkWithTimeout("/flash/#{p}",1) }
      end
    end
  end
end
