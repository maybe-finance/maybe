class Period
    attr_reader :name, :date_range

    def self.find_by_name(name)
        INDEX[name]
    end

    def self.names
        INDEX.keys.sort
    end

    def initialize(name: "custom", date_range:)
        @name = name
        @date_range = date_range
    end

    BUILTIN = [
        new(name: "all", date_range: nil..Date.current),
        new(name: "last_7_days", date_range: 7.days.ago.to_date..Date.current),
        new(name: "last_30_days", date_range: 30.days.ago.to_date..Date.current),
        new(name: "last_365_days", date_range: 365.days.ago.to_date..Date.current)
    ]

    INDEX = BUILTIN.index_by(&:name)

    BUILTIN.each do |period|
        define_singleton_method(period.name) do
            period
        end
    end
end
