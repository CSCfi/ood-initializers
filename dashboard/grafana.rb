class CSCGrafana

  class << self
    def grafana_url
      ENV.fetch("OOD_CSC_GRAFANA", "")
    end

    def panels
      ENV.fetch("OOD_CSC_GRAFANA_PANELS", "").split(",").map(&:to_i)
    end

    def enabled
      grafana_url.present? && !panels.empty?
    end

    def time_range
      "3d"
    end
  end
end
