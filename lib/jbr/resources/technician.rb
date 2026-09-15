module Jbr
  # A person the business sends out, whom Jobber calls a user and whose name is a node of its
  # own rather than two fields, so the vocabulary's keys would not fetch it.
  class Technician < Company::Technician
    # What Jobber answers a user with.
    FIELDS = 'id name { first last }'

    # What to ask for wherever a scheduled item names who it is booked for: ten, which is more
    # than a stop is ever booked for. An app never granted the Users scope has the whole query
    # refused rather than this field left empty, so nothing asks for it unbidden.
    SELECTION = "assignedUsers(first: 10) { nodes { #{FIELDS} } }"

    # @return [String, nil] what they go by: a given name.
    def name = @node.dig :name, :first

    # @return [String, nil] their surname.
    def surname = @node.dig :name, :last
  end
end
