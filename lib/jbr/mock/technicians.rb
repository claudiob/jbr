module Jbr
  # The technicians an app under test asked {Jbr.mock} to answer with.
  class Mock::Technicians < Technicians
  private

    def walk(_statement)
      Enumerator.new do |yielder|
        Jbr.mock.technicians.to_a.each { |node| yielder << Company::Technician.new(node: node) }
      end
    end
  end
end
