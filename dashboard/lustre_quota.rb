require "ffi"
require "json"

begin
  module LustreQuotaInterop
    extend FFI::Library
    LIB_NAME = "quota#{::CSCConfiguration.enable_flash? ? "" : "-no-flash" }"
    # libquota.so should be under CSC_OOD_DEPS_PATH, but can set LD_LIBRARY_PATH to override.
    ffi_lib [
      LIB_NAME,
      "lib#{LIB_NAME}.so",
      File.join(ENV.fetch("CSC_OOD_DEPS_PATH", "/var/www/ood/deps"), "lib", "lib#{LIB_NAME}.so"),
    ]

    attach_function :get_quotas, [:pointer], :pointer
    attach_function :free_quotas, [:pointer], :void
  end
# Need to rescue LoadError to not crash OOD completely if lib is missing.
rescue LoadError => e
  Rails.logger.error("Error loading lustre-quota: #{e.message}")
end

module LustreQuota
  class CQuota < FFI::Struct
    # Can these constants be retrieved from the libquota?
    @@MAX_GRP_LEN = 128
    @@MAX_USR_LEN = 128
    @@PATH_MAX = 4096
    layout :kbyte_current, :long_long,
           :kbyte_soft_limit, :long_long,
           :kbyte_hard_limit, :long_long,
           :file_current, :long_long,
           :file_soft_limit, :long_long,
           :file_hard_limit, :long_long,
           :lustre_proj, :long_long,
           :filepath, [:char, @@PATH_MAX],
           :lustre_id, :long,
           :groupid, :long,
           :groupname, [:char, @@MAX_GRP_LEN],
           :userid, :long,
           :username, [:char, @@MAX_USR_LEN]
  end

  # Returns a Hash Array with the quotas from libquota
  def self.get_quotas()
    # Pointers for num_quota and quota array
    p_num_quotas = FFI::MemoryPointer.new(:int)
    p_quotas = LustreQuotaInterop.get_quotas(p_num_quotas)

    num_quotas = p_num_quotas.read(FFI::NativeType::INT32)

    # Loop through the quota array and convert them to Hash
    quotas = num_quotas.times.map { |idx|
      # There might be some more convenient way to get each quota in the array
      q = CQuota.new(p_quotas + idx * CQuota.size)
      # Convert each FFI type to a Ruby type in a Hash
      # CharArray not converted automatically for some reason
      Hash[q.members.map { |m| [m, q[m].instance_of?(FFI::StructLayout::CharArray) ? q[m].to_s : q[m]] }]
    }
    LustreQuotaInterop::free_quotas(p_quotas)
    quotas
  end

  def self.get_quota_warning_json
    user = Etc.getpwuid.name
    quotas = self.get_quotas.map do |q|
      {
        :type => "user",
        :path => q[:filepath],
        :user => user,
        :total_file_usage => q[:file_current],
        :file_limit => q[:file_soft_limit],
        :total_block_usage => q[:kbyte_current],
        :block_limit => q[:kbyte_soft_limit],
      }
    end

    # JSON schema: https://osc.github.io/ood-documentation/latest/customizations.html#disk-quota-warnings-on-dashboard
    {:version => 1, :timestamp => Time.now.getutc.to_i, :quotas => quotas}.to_json
  end

  def self.write_quota_warning_json(path)
    File.write(path, self.get_quota_warning_json)
  rescue => e
    Rails.logger.error("Error writing quota warning JSON: #{e.message}")
  end
end
