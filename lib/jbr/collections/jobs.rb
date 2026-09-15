module Jbr
  # The jobs on a Jobber account, oldest first, walked a page at a time.
  class Jobs < Collection
    include Includable, Listable

    # What a job answers with wherever one is read, before anything it was asked to bring back
    # with it. Written by hand where the vocabulary's keys would not do: the quote nests.
    FIELDS = 'id title instructions total createdAt startAt completedAt ' \
             'quote { id amounts { total } }'

    # Shadows Enumerable#find on purpose, the way Active Record does: a job is reached by the
    # ID Jobber files it under, not by asking every job on the account whether it is the one.
    # @param id [String] Jobber ID of the job.
    # @return [Job, nil] nil when Jobber has no job under that ID.
    def find(id)
      node = @account.query(one, variables: { id: id })['job']
      Job.new node: node if node
    end

  private

    def page = paged row(FIELDS), PAGE

    def one
      <<~GRAPHQL
        query($id: EncodedId!) {
          job(id: $id) { #{row FIELDS} }
        }
      GRAPHQL
    end

    def field = 'jobs'

    def filtered = 'JobFilterAttributes'

    def item(node) = Job.new node: node
  end
end
