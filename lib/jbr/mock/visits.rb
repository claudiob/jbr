module Jbr
  # The visits an app under test asked {Jbr.mock} to answer with. Only the walk is mocked:
  # narrowing a list, and reading it as records or as IDs, is the same code a real one runs,
  # so a list nothing narrowed refuses here exactly as Jobber refuses it.
  class Mock::Visits < Visits
    # @param id [String] ID the app filed the visit under.
    # @return [Mock::Visit, nil] visit the app listed under that ID, nil where it listed none.
    def find(id)
      node = Jbr.mock.visits.to_a.find { |visit| visit[:id] == id }
      Mock::Visit.new node: node if node
    end

    # @return [Mock::Visit] stop the app listed as its lead, booked for the hour asked for.
    def create(starts_at:, ends_at:, technicians:, **)
      Mock::Visit.new node: { id: 'visit-01', starts_at: starts_at, ends_at: ends_at,
                              technicians: technicians.map { |each| { id: each.id } },
                              lead: Jbr.mock.lead.to_h, }
    end

  private

    def walk(_statement)
      Enumerator.new do |yielder|
        selected.each { |node| yielder << Mock::Visit.new(node: node) }
      end
    end

    def selected
      Jbr.mock.visits.select do |visit|
        scheduled?(visit[:starts_at]) && assigned?(visit) && kind?(visit)
      end
    end

    def scheduled?(at)
      window = @filter&.dig :occursWithin
      return true unless window && at

      at >= Time.iso8601(window[:startAt]) && at <= Time.iso8601(window[:endAt])
    end

    def assigned?(visit)
      wanted = @filter&.dig :assignedTo
      return true unless wanted

      Array(visit[:technicians]).any? { |technician| wanted.include? technician[:id] }
    end

    def kind?(visit)
      kind = @filter&.dig :scheduleItemType
      return true unless kind

      kind == 'VISIT' ? !visit[:job].nil? : !visit[:lead].nil?
    end
  end
end
