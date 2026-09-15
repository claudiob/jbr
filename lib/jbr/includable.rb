module Jbr
  # Extends a list of records with the chaining that says what to bring back beside them.
  # Nothing extra comes back unasked: a page costs what it carries.
  module Includable
    # @param names [Array<Symbol, Hash>] :lines, :technicians, :location, or location: :customer
    #   for whose place it is.
    # @return [Collection] the same list, asking Jobber for those too.
    def includes(*names)
      named = names.each_with_object({}) do |name, all|
        name.is_a?(Hash) ? all.merge!(name) : all[name] = nil
      end
      self.class.new account: @account, includes: @includes.merge(named), filter: @filter
    end

  private

    def row(fields) = [ fields, selections ].compact_blank.join ' '

    def selections = @includes.map { |name, nested| selection_of name, nested }.join ' '

    def selection_of(name, nested)
      case name
        when :lines then Line::SELECTION
        when :technicians then Technician::SELECTION
        when :location then Location.selection customer: nested == :customer
      end
    end
  end
end
