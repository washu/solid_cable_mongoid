# frozen_string_literal: true

module SolidCableMongoid
  class Message
    include Mongoid::Document
    store_in collection: "#{collection_prefix}_message"
    field :channel, type: String
    field :message, type: String
    field :expiry, type: DateTime
    index({ expiry: 1 }, { expire_after_seconds: 0 })
    index({ channel: 1 })
  end
end
