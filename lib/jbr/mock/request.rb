module Jbr
  class Mock::Request < Request
    def create(_)
      @id = Jbr.mock.request[:id]
      @client_id = Jbr.mock.request[:client_id]

      self
    end
  end
end
