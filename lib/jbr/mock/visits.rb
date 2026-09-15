module Jbr
  # The visits an app under test asked {Jbr.mock} to answer with. Only the walk is mocked:
  # narrowing a list, and reading it as records or as IDs, is the same code a real one runs.
  class Mock::Visits < Visits
    # @param id [String] ID the app filed the visit under.
    # @return [Mock::Visit, nil] visit the app listed under that ID, nil where it listed none.
    def find(id)
      node = Jbr.mock.visits.to_a.find { |visit| visit[:id] == id }
      Mock::Visit.new node: node if node
    end

  private

    def walk(_statement)
      Enumerator.new do |yielder|
        selected.each { |node| yielder << Mock::Visit.new(node: node) }
      end
    end

    def selected
      Jbr.mock.visits.select { |visit| scheduled?(visit[:starts_at]) && assigned?(visit) }
    end

    def assigned?(visit)
      id = @filter&.dig :assignedTo
      return true unless id

      Array(visit[:technicians]).any? { |technician| technician[:id] == id }
    end
  end
end
