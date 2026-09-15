module Jbr
  # A visit an app under test listed, keyed by the vocabulary's names rather than Jobber's.
  class Mock::Visit < Visit
    # The mock spells every key as the reader is named.
    def self.keys = {}

    # @return [Array<Company::Technician>] whoever the app said the visit is booked for.
    def technicians = records Company::Technician, :technicians
  end
end
