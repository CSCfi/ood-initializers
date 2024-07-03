module CSCModules
  GLOBAL_MODULES_DIR = "/appl/modulefiles/courses"
  PRIVATE_MODULES_DIR = File.join(Dir.home, "privatemodules")
  # e.g. /projappl/<project>/www_mahti_modules
  PROJECT_MODULES_DIR = "www_#{ENV["CSC_CLUSTER"]}_modules"

  MODULE_SPIDER_FILE = "/opt/csc/modules.json"

  # Struct for a modules not in the normal module tree
  Module = Struct.new(:name, :path, :test, :global, :project, :resources, keyword_init: true) do
    class << self
      def from_path(path)
        if path.blank?
          raise "No module was selected. If you do not see any module in the dropdown, there are no available modules for that project.\nPlease create a module or select one from a different project."
        end
        # Test module (needs `module load use.own`)
        test = path.start_with?(PRIVATE_MODULES_DIR)
        # Global module (available to everyone, need to prefix module load with course/)
        global = path.start_with?(GLOBAL_MODULES_DIR)
        if test
          name = path.split(PRIVATE_MODULES_DIR).last.delete_prefix("/")
        elsif global
          name = path.split(GLOBAL_MODULES_DIR).last.delete_prefix("/")
        else
          # Project for the module if in /projappl or /scratch
          project = path.split(PROJECT_MODULES_DIR).first.split("/").last
          name = path.split(PROJECT_MODULES_DIR).last.delete_prefix("/")
        end
        # Resources are nil if file is missing
        resources = Resources.from_path(path, project: project)
        self.new(name: name, path: path, test: test, global: global, project: project, resources: resources)
      end
    end

    # The path without the module name for MODULEPATH.
    # E.g. /projappl/<project>/www_mahti_modules, $HOME/privatemodules or /appl/modulefiles.
    def modulepath
      path.delete_suffix(name).delete_suffix("/")
    end

    # The full definition of the option in the select element in the form
    def form_definition
      @form_definition ||=
        [
          name,
          path,
          *form_data,
        ]
    end

    # Data for the BC_DYNAMIC_JS feature for form
    def form_data
      projects_data = (CSCModules.groups - [project])
        .map { |p| { "data-option-for-csc-slurm-project-#{p.gsub(/_/, "-")}".to_sym => false } } unless project.nil?
      [
        {
          "data-test".to_sym => test,
          "data-project".to_sym => project,
          "data-path".to_sym => path,
        }.compact,
        *resources&.form_data,
        *projects_data,
      ]
    end
  end

  # Struct for the resources of a module, loaded from a YML file for each module
  Resources = Struct.new(:cores, :time, :mem, :local_disk, :partition, :reservation, :working_dir, :project, keyword_init: true) do
    class << self
      def from_path(path, project: nil)
        if File.extname(path) == ".yml"
          # Path already pointing to the resources yml
          Resources.new({:project => project}.deep_merge(YAML.load_file(path).symbolize_keys))
        else
          # Path to course
          Resources.new({:project => project}.deep_merge(YAML.load_file("#{path}-resources.yml").symbolize_keys))
        end
      rescue => e
        # Missing resources
        nil
      end
    end

    # Data for BC_DYNAMIC_JS feature
    def form_data
      [
        {
          "data-set-csc-cores".to_sym => cores,
          "data-set-csc-time".to_sym => time,
          "data-set-csc-memory".to_sym => (mem.to_i.to_s unless mem.nil?),
          "data-set-csc-nvme".to_sym => local_disk,
          "data-set-csc-slurm-partition".to_sym => partition,
          "data-csc-slurm-reservation".to_sym => reservation,
          "data-set-notebook-dir".to_sym => working_dir&.gsub("$PROJECT", project)&.gsub("$USER", Etc.getpwuid.name)&.gsub("$HOME", Dir.home),
        }.compact,
      ]
    end
  end

  class << self
    def groups
      @groups ||= User.new.groups.map(&:name)
    end

    # All modules in project directories
    def get_project_modules
      modules = groups.map do |p|
        path = "/projappl/#{p}/#{PROJECT_MODULES_DIR}"
        search_path(path).map do |name|
          Module.from_path(File.join(path, name))
        end
      end.flatten(1)
      modules
    end

    # Searches path for modules containing "Jupyter", can include the name of the directory or not
    def get_jupyter_modules(path)
      search_path(path, "Jupyter").map do |name|
        Module.from_path(File.join(path, name))
      end
    end

    # Get CSC course modules containing Jupyter
    def get_jupyter_course_modules
      get_jupyter_modules(GLOBAL_MODULES_DIR)
    end

    # Get modules containing "Jupyter" for all projects
    def get_jupyter_projappl_modules
      modules = groups.map do |p|
        get_jupyter_modules("/projappl/#{p}/#{PROJECT_MODULES_DIR}")
      end.flatten(1)
      modules
    end

    # Get test/private modules
    def get_jupyter_private_modules
      get_jupyter_modules(PRIVATE_MODULES_DIR)
    end

    def module_spider
      @@module_spider ||= JSON.parse(File.read(MODULE_SPIDER_FILE))
    rescue => e
      Rails.logger.error("Error reading module spider file at #{MODULE_SPIDER_FILE}: #{e}")
      []
    end

    def all_versions(name)
      mod = module_spider.find { |m| m["package"] == name }
      default = mod["defaultVersionName"]
      # Sorted list of full module names, with default module first
      versions = mod["versions"]
        .sort_by { |v| [v["versionName"] == default ? 1 : 0, v["versionName"].split(/[,-]/).map(&:to_i)] }
        .map { |v| { name: v["full"], default: v["versionName"] == default } }
        .reverse
      versions
    end

    def default_version(name)
      mod = module_spider.find { |m| m["package"] == name }
      default = mod["defaultVersionName"]
      "#{mod["package"]}/#{default}"
    end

    # Searches a path for modules, filters for string in the file
    # same as
    # cd <path> && grep -l <filter> *.lua | cut -d "." -f1
    def search_path(path, filter = "")
      path = path.chomp("/")
      filter = "" if filter.nil?

      # expand *.lua for grep
      files = Dir.glob("#{path}/*.lua")
      stdout_str, status = Open3.capture2("grep", "-il", filter, *files)
      # No files found/exist
      return [] unless status.success?
      # Return only module names
      stdout_str.split.map { |p| Pathname.new(p).basename(".lua").to_s }
    end
  end
end
