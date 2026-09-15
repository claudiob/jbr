module Jbr
  # What Jobber files as a scheduled item, and how a list of them is asked for. Which kinds count
  # as booked time lives here, and so does the awkward part: a scheduled item names no property
  # and no job, so where a stop is and what it was booked for hang off each kind rather than off
  # what they share, and are selected inside the fragments.
  module Scheduled
    # What every kind answers with.
    SHARED = '__typename id title startAt endAt allDay'

    # The kinds that are booked time. A reminder is a notification rather than an hour somebody
    # is out, and Jobber's filter takes one kind and not two, so every kind is asked for and the
    # reminders are let go as they arrive. `Task` is the name Jobber gives a BASIC_TASK, which no
    # account read so far has answered with.
    KINDS = %w[Visit Assessment Event Task]

  private

    def fields
      [ SHARED, kind('Visit', 'clientConfirmed job { id }'),
        kind('Assessment', 'clientConfirmed request { id }') ].join ' '
    end

    def kind(name, own) = "... on #{name} { #{[ own, located ].compact_blank.join ' '} }"

    def alone = [ 'id title startAt endAt allDay clientConfirmed job { id }', located ].
      compact_blank.join ' '

    # Included before Includable so this is found first: a location asked for is selected inside
    # each kind's fragment by `kind`, and must not also be appended to what they share, where
    # Jobber has no property to answer with.
    def selection_of(name, nested)
      return if name == :location

      super
    end

    def located
      Location.selection customer: @includes[:location] == :customer if @includes.key? :location
    end

    def item(node) = (Visit.new node: node if KINDS.include? node['__typename'])
  end
end
