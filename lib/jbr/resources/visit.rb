module Jbr
  # One stop of a job: when the work is scheduled to happen, where the job does.
  class Visit < Company::Visit
    # What every visit reads: the vocabulary's names, and whether the client confirmed it,
    # which Jobber alone asks.
    def self.attributes = super + %i[confirmed]

    # The node keys Jobber spells otherwise than the vocabulary.
    def self.keys
      { description: :title, starts_at: :startAt, ends_at: :endAt, anytime: :allDay,
        confirmed: :clientConfirmed, }
    end

    # @return [Boolean, nil] whether the client confirmed the visit.
    def confirmed? = attribute :confirmed

    # @return [Array<Technician>] whoever the stop is booked for, where the query asked.
    def technicians = @node.dig(:assignedUsers, :nodes).to_a.map { Technician.new node: it }
  end
end
