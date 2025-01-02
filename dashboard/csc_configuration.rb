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
  end
end
