class CSCBalance
  class InvalidBalanceFile < StandardError; end

  attr_reader :project, :value, :maxvalue, :updated_at

  include ActionView::Helpers::NumberHelper

  class << self

    def get
      @last_update = Time.new
      @balances = CSCBalance.find(ENV["OOD_CSC_BALANCE_PATH"])
    end
    # Get balance objects only for requested user in JSON file(s)
    #
    # KeyError and JSON::ParserErrors shall be non-fatal errors
    def find(balance_path)
      raw = open(balance_path).read
      raise InvalidBalanceFile.new("No content returned when attempting to read balance file") if raw.nil? || raw.empty?

      # Attempt to parse raw JSON into an object
      json = JSON.parse(raw)
      raise InvalidBalanceFile.new("Balance file expected to be a JSON object with balances array section") unless json.is_a?(Hash) && json["balances"].respond_to?(:each)

      #FIXME: any validation of the structure here? otherwise we don't need the complexity of the code below
      # until we have more than one balance version schema, which we do not
      # so assume version is 1
      build_balances(json["balances"], json["timestamp"])
    rescue StandardError => e
      Rails.logger.error("Error #{e.class} when reading and parsing balance file #{balance_path} for user #{user}: #{e.message}")
      [e.to_s]
    end

    private

    def ignore_duration
      ENV.fetch("OOD_CSC_BALANCE_IGNORE_TIME", 0).to_i
    end

    def ignored_balances
      raw = open(ignored_balances_file).read
      raise Error("Error reading ignored balances") if raw.nil? || raw.empty?
      json = JSON.parse(raw)
      raise Error("Invalid JSON in ignored balances") unless json.is_a?(Array)

      json
      rescue StandardError => e
        []
    end

    def ignored_balances_file
      "#{Configuration.dataroot}/ignored_balances.json"
    end

    def ignore_balance?(balance, ignored)
      ignored.any? { |b|
        balance.project.to_s == b["project"] && ( ignore_duration == 0 || @last_update < Time.at(b["timestamp"].to_i/1000) + ignore_duration.days)
      }
    end

    # Parse JSON object using version 1 formatting
    def build_balances(balance_hashes, updated_at)
      balances = []
      balance_hashes.each do |balance|
        balance = balance.to_h.compact.symbolize_keys
        balances << CSCBalance.new(
          project: balance.fetch(:project, nil).to_s,
          value: balance.fetch(:value).to_i,
          maxvalue: balance.fetch(:maxvalue).to_i,
          updated_at: Time.at(updated_at.to_i),
        )
      end
      ignored = ignored_balances
      balances.reject { |b| ignore_balance?(b, ignored) }
    end
  end

  # @param params [#to_h] list of parameters that define balance object
  # @option params [#to_s] :project project name
  # @option params [#to_i] :value balance value
  # @option params [#to_i] :updated_at time when balance was generated
  def initialize(params)
    params = params.to_h.compact.symbolize_keys
    @project = params.fetch(:project, nil).to_s
    @value = params.fetch(:value).to_i
    @maxvalue = params.fetch(:maxvalue).to_i
    @updated_at = Time.at(params.fetch(:updated_at).to_i)
  end

  def limited?
    @maxvalue > 0
  end

  def percent_usage
    if limited?
      (@value * 100) / @maxvalue
    else
      0
    end
  end

  def sufficient?(threshold: 0)
    if limited?
      @value > threshold * @maxvalue
    else
      true
    end
  end

  def insufficient?(threshold: 0)
    !sufficient?(threshold: threshold)
  end

  def to_s
    "#{number_to_human(@value).downcase} out of #{number_to_human(@maxvalue).downcase} BUs remaining"
  end
end
