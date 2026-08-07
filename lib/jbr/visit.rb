module Jbr
  # One stop at a property: when the work on a job is scheduled to happen.
  class Visit < Resource
    # The query that reads a page of visits starting after a moment, oldest first. Forty a
    # page, not a hundred: Jobber prices a query by its page size and refuses the wider one.
    UPCOMING = <<~GRAPHQL
      query($after: String, $from: ISO8601DateTime!) {
        visits(first: 40, after: $after, filter: { startAt: { after: $from } }) {
          nodes { id title startAt endAt job { id } }
          pageInfo { hasNextPage endCursor }
        }
      }
    GRAPHQL

    # @param oauth [OAuth] the credentials to reach Jobber with.
    # @param node [Hash] the visit as Jobber answered it.
    def initialize(oauth:, node: {})
      super oauth: oauth
      @node = node
    end

    # The visits scheduled from now on, oldest first. Nothing is read until the enumerator
    # is walked, and a page is read only once the one before it runs out.
    # @return [Enumerator<Visit>] the account's upcoming visits.
    def upcoming
      Enumerator.new do |yielder|
        nodes.each { |node| yielder << self.class.new(oauth: @oauth, node: node) }
      end
    end

    # @return [String, nil] the Jobber ID of the visit.
    def id = @node['id']

    # @return [String, nil] what the visit is called.
    def title = @node['title']

    # @return [String, nil] the ID of the job the visit belongs to.
    def job_id = @node.dig 'job', 'id'

    # @return [Time, nil] the visit start time
    def starts_at
      Time.iso8601(@node['startAt']) if @node['startAt']
    end

    # @return [Time, nil] the visit end time
    def ends_at
      Time.iso8601(@node['endAt']) if @node['endAt']
    end

  private

    # The moment is stamped once, before the first page: read per page, it would slide
    # forward and drop a visit that started while the pages were being walked.
    def nodes
      Enumerator.new do |yielder|
        from, after = Time.now.iso8601, nil
        loop do
          page = @oauth.query(UPCOMING, variables: { after: after, from: from }).fetch 'visits', {}
          page.fetch('nodes', []).each { |node| yielder << node }
          break unless page.dig 'pageInfo', 'hasNextPage'

          after = page.dig 'pageInfo', 'endCursor'
        end
      end
    end
  end
end
