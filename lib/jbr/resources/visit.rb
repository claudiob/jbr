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

    # Jobber calls the lead a request, and hangs the assessment booked to look at the work off
    # it; a stop of a job names no request and a stop of a lead names no job.
    # @return [Lead, nil] lead the stop belongs to, nil where the stop is a job's.
    def lead = record Lead, :request

    # Jobber hangs the property off each kind of scheduled item rather than off what they
    # share, so it is asked for inside each and read back under Jobber's own name for it.
    # @return [Location, nil] where the stop happens, where the query asked and Jobber has one.
    def location = record Location, :property

    # @return [Array<Technician>] whoever the stop is booked for, where the query asked.
    def technicians = @node.dig(:assignedUsers, :nodes).to_a.map { Technician.new node: it }
  end
end
