module Jbr
  # The visits on a Jobber account, oldest first, walked a page at a time.
  class Visits < Collection
    include Includable, Listable

    # What a visit answers with: the keys the vocabulary reads, and the job it belongs to.
    FIELDS = "#{Visit.node_keys.join ' '} job { id }"

    # Shadows Enumerable#find on purpose, the way jobs do: a visit is reached by the ID Jobber
    # files it under, not by asking every visit on the account whether it is the one.
    # @param id [String] Jobber ID of the visit.
    # @return [Visit, nil] nil when Jobber has no visit under that ID.
    def find(id)
      node = @account.query(one, variables: { id: id })['visit']
      Visit.new node: node if node
    end

    # Jobber narrows a list of visits by who is on it, so the technician joins the window in
    # the one filter and nobody else's visits are answered, paged or paid for.
    # @param technician [Company::Technician] whoever the work is booked for.
    # @return [Visits] the same list, narrowed to the visits they are booked for.
    def assigned_to(technician) = narrowed(assignedTo: technician.id)

  private

    def page = paged row(FIELDS), PAGE

    def one
      <<~GRAPHQL
        query($id: EncodedId!) {
          visit(id: $id) { #{row FIELDS} }
        }
      GRAPHQL
    end

    def field = 'visits'

    def filtered = 'VisitFilterAttributes'

    def item(node) = Visit.new node: node
  end
end
