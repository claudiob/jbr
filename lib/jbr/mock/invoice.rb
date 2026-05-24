module Jbr
  class Mock::Invoice < Invoice
    def find(_)
      @id = Jbr.mock.invoice[:id]
      @job_id = Jbr.mock.invoice[:job_id]
      @total = Jbr.mock.invoice[:total]

      self
    end

    def issued_at = Jbr.mock.invoice[:issued_at]

    def completed_at = Jbr.mock.invoice[:completed_at]
  end
end
