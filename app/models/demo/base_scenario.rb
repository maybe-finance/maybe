# Base class for demo scenario handlers - subclasses must implement generate_family_data!
class Demo::BaseScenario
  def initialize(generators)
    @generators = generators
  end

  def generate!(families, **options)
    setup(**options) if respond_to?(:setup, true)

    families.each do |family|
      ActiveRecord::Base.transaction do
        generate_family_data!(family, **options)
      end
      puts "#{scenario_name} data created for #{family.name}"
    end
  end

  private

    def setup(**options)
    end

    def generate_family_data!(family, **options)
      raise NotImplementedError, "Subclasses must implement generate_family_data!(family, **options)"
    end

    def scenario_name
      self.class.name.split("::").last.downcase.gsub(/([a-z])([A-Z])/, '\1 \2')
    end
end
