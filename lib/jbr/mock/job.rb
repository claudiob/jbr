module Jbr
  class Mock::Job < Job
    def find(_)
      @id = Jbr.mock.job[:id]
      @quote_id = Jbr.mock.job[:quote_id]

      self
    end

    def scheduled_at = Jbr.mock.job[:scheduled_at]

    def completed_at = Jbr.mock.job[:completed_at]
  end
end
