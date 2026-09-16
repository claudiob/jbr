require 'logger'

module Jbr
  class << self
    # Where this gem says what it could not do, for the things it carries on from rather than
    # raises. An app with a log of its own points this at it.
    # @return [Logger] somewhere to write, standard error until an app names somewhere better.
    def logger = @logger ||= Logger.new($stderr)

    # @return [Logger] where to write.
    attr_writer :logger
  end
end
