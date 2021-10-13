# Note: When editing this file, changes will only take effect
# AFTER the PUNs are refreshed.

require_relative "./balance.rb"
require_relative "./quota.rb"

OodFilesApp.candidate_favorite_paths.tap do |paths|
  # Add each user's project projappl and scratch directories to the
  # file app as links.
  projects = User.new.groups.map(&:name)
  # Assuming that the directories are named like the projects.
  paths.concat projects.map { |p| FavoritePath.new("/projappl/#{p}") }
  paths.concat projects.map { |p| FavoritePath.new("/scratch/#{p}") }
end

# Based on https://discourse.osc.edu/t/set-order-of-interactive-apps-menu-items/1271
def OodAppGroup.groups_for(apps: [], group_by: :category, nav_limit: nil)
  grouped = apps.group_by { |app|
    app.respond_to?(group_by) ? app.send(group_by) : app.metadata[group_by]
  }.map { |k,v|
    OodAppGroup.new(title: k, apps: v.sort_by { |a| a.title }, nav_limit: nav_limit)
  }.sort_by { |g| [ g.title.nil? ? 1 : 0, g.title ] }

  if group_by.to_s == "subcategory" then
    # Sort Course environments subcategory to end
    grouped.sort_by { |g| g.title == "Course environments" ? 1 : 0}
  else
    grouped
  end
end

NavConfig.categories_whitelist=true
NavConfig.categories=["Files", "Jobs", "Apps​", "Terminal", "Tools"]

# Add quota and balance file path for the user
ENV["OOD_CSC_QUOTA_PATH"] = "/tmp/#{ENV["USER"]}_ood_quotas.json"
ENV["OOD_CSC_BALANCE_PATH"] = "/tmp/#{ENV["USER"]}_ood_balance.json"
ENV["ENABLE_NATIVE_VNC"] = "yes"
ENV["OOD_NATIVE_VNC_LOGIN_HOST"] = "puhti.csc.fi"

ENV["SLURM_OOD_ENV"] = case ENV["CSC_OOD_ENVIRONMENT"]
                       when "production"
                         "prod"
                       when "staging"
                         "staging"
                       when "future"
                         "future"
                       when "testing"
                         "test"
                       else 
                         "test"
                       end




# These are temporary for debug only, should/could be defined elsewhere
#ENV["OOD_QUOTA_THRESHOLD"] = ENV.fetch("OOD_QUOTA_THRESHOLD", "0.95")
# Balance threshold to include all balances, filtering is done when creating JSON
#ENV["OOD_BALANCE_THRESHOLD"] = ENV.fetch("OOD_BALANCE_THRESHOLD", "0.05")
# Update quota and balance JSON files in tmp, set BU limit to 5%
system({"LD_LIBRARY_PATH" => "/ood/deps/lib:#{ENV["LD_LIBRARY_PATH"]}"}, "/ood/deps/soft/csc-projects", "-b", "#{ENV["OOD_CSC_BALANCE_PATH"]}", "-q", "#{ENV["OOD_CSC_QUOTA_PATH"]}")
