module Jbr
  # What a list read through the credentials holds: what to reach Jobber with, what to bring
  # back beside each record, and what the list was narrowed to. A list of visits answers the
  # vocabulary's own {Company::Visits} rather than {Collection}, so the three live here.
  module Reading
    # @param account [Account] credentials to reach Jobber with.
    # @param includes [Hash] what to bring back beside each record, by name.
    # @param filter [Hash, nil] what the list was narrowed to, in the shape Jobber filters by.
    def initialize(account:, includes: {}, filter: nil)
      @account = account
      @includes = includes
      @filter = filter
    end
  end
end
