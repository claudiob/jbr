module Jbr
  # The users on a Jobber account, walked a page at a time. Reading one at all needs the Users
  # scope; narrowing a list to one does not.
  class Technicians < Collection
    include Listable

  private

    def page = paged Technician::FIELDS, PAGE

    def field = 'users'

    def filtered = 'UsersFilterAttributes'

    def item(node) = Technician.new node: node
  end
end
