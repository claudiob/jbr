module Jbr
  # The visits on a Jobber account: the stops of its jobs, and the assessments booked to go and
  # look at work before there is a job. Jobber files both as scheduled items and refuses to list
  # one without a window, so a list nothing narrowed has none to give and says so.
  class Visits < Company::Visits
    include Reading, Scheduled, Includable, Listable, Booking

    # How far an open end reaches. Jobber's window takes two moments and no nil, so a caller
    # who named no end gets a year of one, which is a schedule rather than an archive.
    HORIZON = 1.year

    # Shadows Enumerable#find on purpose, the way jobs do: a visit is reached by the ID Jobber
    # files it under, not by asking every visit on the account whether it is the one. Jobber
    # files an assessment under a lookup of its own, so this one answers a job's stop alone.
    # @param id [String] Jobber ID of the visit.
    # @return [Visit, nil] nil when Jobber has no visit under that ID.
    def find(id)
      node = @account.query(one, variables: { id: id })['visit']
      Visit.new node: node if node
    end

    # @param from [Time, nil] the moment the window opens, or nothing for as far back as there is.
    # @param to [Time, nil] the moment the window closes, or nothing for as far ahead as there is.
    # @return [Visits] the same list, narrowed to what the window holds.
    def between(from, to)
      now = Time.now
      narrowed occursWithin: { startAt: (from || now - HORIZON).iso8601,
                               endAt: (to || now + HORIZON).iso8601 },
        schedulingAspects: [ 'ALL' ]
    end

    # Jobber narrows a schedule by who is on it, so the technician joins the window in the one
    # filter and nobody else's work is answered, paged or paid for.
    # @param technician [Company::Technician] whoever the work is booked for.
    # @return [Visits] the same list, narrowed to what they are booked for.
    # @note Needs no Users scope: Jobber narrows, and no user is selected to do it.
    def assigned_to(technician) = narrowed(assignedTo: [ technician.id ])

    # @return [Visits] the same list, narrowed to the stops of jobs, by Jobber rather than here.
    def for_jobs = narrowed(scheduleItemType: 'VISIT')

    # @return [Visits] the same list, narrowed to the assessments, by Jobber rather than here.
    def for_leads = narrowed(scheduleItemType: 'ASSESSMENT')

    # @yield [Visit] each visit in the window, oldest first.
    def each(&)
      windowed
      super
    end

    # @return [Array<String>] every ID in the window, every page of them read.
    def ids
      windowed
      super
    end

  private

    def windowed
      return if @filter&.key? :occursWithin

      raise Error, 'A Jobber schedule is read by the window: ask between, upcoming or past'
    end

    def page = paged row(fields), PAGE

    def one
      <<~GRAPHQL
        query($id: EncodedId!) {
          visit(id: $id) { #{row alone} }
        }
      GRAPHQL
    end

    def field = 'scheduledItems'

    def filtered = 'ScheduledItemsFilterAttributes!'
  end
end
