module Jbr
  class Mock::Quote < Quote
    def find(_)
      @id = Jbr.mock.quote[:id]
      @request_id = Jbr.mock.quote[:request_id]

      self
    end
  end
end
