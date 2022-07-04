# Note: When editing this file, changes will only take effect
# AFTER the PUNs are refreshed.

require_relative "./balance.rb"
require_relative "./quota.rb"
require_relative "./app_session_info.rb"
require_relative "./grafana.rb"

# Require the smart attributes for batch connect forms
require "smart_attributes"
require "#{ENV["CSC_OOD_DEPS_PATH"]}/util/attributes/csc_smart_attributes"

OodFilesApp.candidate_favorite_paths.tap do |paths|
  # Add each user's project projappl and scratch directories to the
  # file app as links.
  projects = User.new.groups.map(&:name)
  # Assuming that the directories are named like the projects.
  paths.concat projects.filter_map { |p| FavoritePath.new(File.realpath("/projappl/#{p}")) if File.exist?("/projappl/#{p}") }
  paths.concat projects.filter_map { |p| FavoritePath.new(File.realpath("/scratch/#{p}")) if File.exist?("/scratch/#{p}") }
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

NavConfig.categories=["Files", "Jobs", "Apps", "Terminal", "Tools"]

# Add quota and balance file path for the user
ENV["OOD_CSC_QUOTA_PATH"] = "/tmp/#{ENV["USER"]}_ood_quotas.json"
ENV["OOD_CSC_BALANCE_PATH"] = "/tmp/#{ENV["USER"]}_ood_balance.json"

ENV["OOD_CSC_QUOTA_IGNORE_TIME"] = ENV.fetch("OOD_CSC_QUOTA_IGNORE_TIME", "14")
ENV["OOD_CSC_BALANCE_IGNORE_TIME"] = ENV.fetch("OOD_CSC_BALANCE_IGNORE_TIME", "14")

ENV["OOD_CSC_QUOTA_THRESHOLD"] = ENV.fetch("OOD_CSC_QUOTA_THRESHOLD", "0.9")
ENV["OOD_CSC_BALANCE_THRESHOLD"] = ENV.fetch("OOD_CSC_BALANCE_THRESHOLD", "0.1")

ENV["ENABLE_NATIVE_VNC"] = ENV.fetch("ENABLE_NATIVE_VNC", "yes")
ENV["OOD_NATIVE_VNC_LOGIN_HOST"] = ENV.fetch("OOD_NATIVE_VNC_LOGIN_HOST", "puhti.csc.fi")

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

# Update quota and balance JSON files in tmp, set BU limit to 5%
system({"LD_LIBRARY_PATH" => "#{ENV["CSC_OOD_DEPS_PATH"]}/lib:#{ENV["LD_LIBRARY_PATH"]}"}, "#{ENV["CSC_OOD_DEPS_PATH"]}/soft/csc-projects", "-b", "#{ENV["OOD_CSC_BALANCE_PATH"]}", "-q", "#{ENV["OOD_CSC_QUOTA_PATH"]}")

# Use OODs default quota warnings for home directory only
# Other quota warnings will be visible in the widget and use env vars OOD_CSC_*
begin
  ENV["OOD_QUOTA_PATH"] = "/tmp/#{ENV["USER"]}_ood_home_quota.json"
  # Read all quotas and filter it to have only home dir
  quota_file = File.read(ENV["OOD_CSC_QUOTA_PATH"])
  home_quotas = JSON.parse(quota_file)
  home_quotas["quotas"] = home_quotas["quotas"].filter{ |quota| quota["path"] == Dir.home }
  File.write(ENV["OOD_QUOTA_PATH"], home_quotas.to_json)
rescue => e
  Rails.logger.error("Failed to create home directory quota file: #{e.message}")
end

if ENV["SSH_KEYGEN_SCRIPT"] != nil
  system("test -x #{ENV['SSH_KEYGEN_SCRIPT']} &&  #{ENV['SSH_KEYGEN_SCRIPT']}" )
end

