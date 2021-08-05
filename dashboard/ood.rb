# Note: When editing this file, changes will only take effect
# AFTER the PUNs are refreshed.

OodFilesApp.candidate_favorite_paths.tap do |paths|
  # Add each user's project projappl and scratch directories to the
  # file app as links.
  projects = User.new.groups.map(&:name)
  # Assuming that the directories are named like the projects.
  paths.concat projects.map { |p| FavoritePath.new("/projappl/#{p}") }
  paths.concat projects.map { |p| FavoritePath.new("/scratch/#{p}") }
end

# Add quota and balance file path for the user
ENV["OOD_QUOTA_PATH"] = "/tmp/#{ENV["USER"]}_ood_quotas.json:" + ENV.fetch("OOD_QUOTA_PATH", "")
ENV["OOD_BALANCE_PATH"] = "/tmp/#{ENV["USER"]}_ood_balance.json:" + ENV.fetch("OOD_BALANCE_PATH", "")
ENV["ENABLE_NATIVE_VNC"] = "yes"
ENV["OOD_NATIVE_VNC_LOGIN_HOST"] = "puhti.csc.fi"

ENV["SLURM_OOD_ENV"] = `df -h | grep ood | cut -d " " -f 1 | rev | cut -d "/" -f 1  | rev`

# These are temporary for debug only, should/could be defined elsewhere
ENV["OOD_QUOTA_THRESHOLD"] = ENV.fetch("OOD_QUOTA_THRESHOLD", "0.95")
# Balance threshold to include all balances, filtering is done when creating JSON
ENV["OOD_BALANCE_THRESHOLD"] = ENV.fetch("OOD_BALANCE_THRESHOLD", "10000000000")

# Update quota and balance JSON files in tmp, set BU limit to 5%
system({"LD_LIBRARY_PATH" => "/appl/opt/ood_util/lib:#{ENV["LD_LIBRARY_PATH"]}"}, "/appl/opt/ood_util/soft/ood-csc-projects", "-b", "/tmp/#{ENV["USER"]}_ood_balance.json", "-q", "/tmp/#{ENV["USER"]}_ood_quotas.json", "-r", "0.05")
