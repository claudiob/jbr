module Jbr
  # A visit that reads from {Jbr.mock} instead of Jobber.
  class Mock::Visit < Visit
    # @return [Enumerator<Mock::Visit>] the visits the app asked for.
    def upcoming
      Enumerator.new do |yielder|
        Jbr.mock.visits.each { |visit| yielder << self.class.new(oauth: @oauth, node: visit) }
      end
    end

    # @return [Object, nil] the values the app asked for.
    def id = @node[:id]

    def title = @node[:title]

    def job_id = @node[:job_id]

    def address = @node.fetch :address, {}

    def all_day? = @node[:all_day]

    def client_confirmed? = @node[:client_confirmed]

    def starts_at = @node[:starts_at]

    def ends_at = @node[:ends_at]
  end
end
