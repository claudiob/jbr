module Jbr
  # What a list of records answers, and how much of an account it costs to ask. Jobber prices
  # a query by the page it asks for and by what every row of that page carries, so a list is
  # read either as records or as the IDs alone, each with a page sized to what it carries.
  module Listable
    # Records a page, not forty and not a hundred: what an includes brings back is charged for
    # on top of every row of it, so a page of jobs carrying their lines, their location and its
    # customer priced past what a bucket holds. Half the page costs half the query and loses
    # nothing, since a walk simply reads more pages.
    PAGE = 20

    # IDs a page, which the same budget affords five times over where a row carries one field
    # and no nesting at all.
    IDS_PAGE = 100

    # Every record the list is narrowed to, oldest first. Nothing is read until the walk
    # starts, and a page is read only once the one before it runs out.
    def each(&) = walk(page).each(&)

    # The two halves of a schedule split at one moment rather than per page: read page by page
    # the boundary would slide, and something could cross it unseen.
    # @param from [Time, nil] the moment the window opens, or nothing for as far back as it goes.
    # @param to [Time, nil] the moment the window closes, or nothing for as far ahead as it goes.
    # @return [Collection] the same list, narrowed to what starts between the two.
    def between(from, to) = narrowed(startAt: { after: from&.iso8601, before: to&.iso8601 }.compact)

    # The ID Jobber files each record under, and nothing else about it: the cheapest question
    # an account can be walked with, and the one to ask where every record is then read on its
    # own through `find`.
    # @return [Array<String>] every ID in the list, every page of them read.
    def ids = walk(ids_page).map(&:id)

  private

    # Every narrowing lands in the one filter Jobber takes, so asking for a week and asking for
    # a technician compose whichever way round a caller writes them.
    def narrowed(**more)
      self.class.new account: @account, includes: @includes, filter: @filter.to_h.merge(more)
    end

    def scheduled?(at)
      bounds = @filter&.dig :startAt
      return true unless bounds

      after, before = bounds.values_at :after, :before
      return before.nil? unless at

      (after.nil? || at >= Time.iso8601(after)) && (before.nil? || at <= Time.iso8601(before))
    end

    def walk(statement)
      Enumerator.new do |yielder|
        after = nil
        loop do
          answered = @account.query statement, variables: { after: after, filter: @filter }.compact
          current = answered.fetch field, {}
          current.fetch('nodes', []).each { |node| yielder << item(node) }
          break unless current.dig 'pageInfo', 'hasNextPage'

          after = current.dig 'pageInfo', 'endCursor'
        end
      end
    end

    def ids_page = paged 'id', IDS_PAGE

    def paged(fields, size)
      <<~GRAPHQL
        query($after: String, $filter: #{filtered}) {
          #{field}(first: #{size}, after: $after, filter: $filter) {
            nodes { #{fields} }
            pageInfo { hasNextPage endCursor }
          }
        }
      GRAPHQL
    end
  end
end
