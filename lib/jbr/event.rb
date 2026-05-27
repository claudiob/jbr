module Jbr
  class Event
    # @see https://developer.getjobber.com/docs/using_jobbers_api/setting_up_webhooks
    SIGNATURE_HEADER = 'X-Jobber-Hmac-SHA256'

    # @param params [Hash] the payload for an event webhook.
    def initialize(params = {})
      @params = params
    end

    # @return [String] unique identifier of the event target.
    def item_id = @params.dig :data, :webHookEvent, :itemId

    # @return [String] unique identifier of the event account.
    def account_id = @params.dig :data, :webHookEvent, :accountId

    # @return [Hash] the shape of the payload send by Jobber to the callback URL.
    def self.params_for(item_id:, account_id:)
      { data: { webHookEvent: { itemId: item_id, accountId: account_id } } }
    end
  end
end
