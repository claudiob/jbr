module Jbr
  # A visit an app under test listed, keyed by the vocabulary's names rather than Jobber's.
  class Mock::Visit < Visit
    # The mock spells every key as the reader is named.
    def self.keys = {}

    # @return [Array<Company::Technician>] whoever the app said the visit is booked for.
    def technicians = records Company::Technician, :technicians

    # @return [Company::Lead, nil] lead the app said the visit was booked against.
    def lead = record Company::Lead, :lead

    # @return [Company::Location, nil] where the app said the visit is.
    def location = record Company::Location, :location
  end
end
