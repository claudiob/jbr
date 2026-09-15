module Jbr
  # A list of records read through the credentials, with what it was asked to bring back beside
  # each record and what it was narrowed to.
  class Collection < Company::Collection
    include Reading
  end
end
