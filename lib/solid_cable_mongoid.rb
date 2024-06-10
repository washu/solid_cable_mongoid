# frozen_string_literal: true

require "solid_cable_mongoid/version"
require "solid_cable_mongoid/engine"
require "action_cable/subscription_adapter/solid_mongoid"

module SolidCableMongoid
  class Error < StandardError; end
  def self.cable_config
    Rails.application.config_for('cable')
  end
  def self.collection_prefix
    cable_config.collection_prefix || 'solid_cable_'
  end

  def self.use_default?
    cable_config.client.blank?
  end

  def self.db_client
    cable_config.client || :default
  end

  def self.expiration
    cable_config.expiration || 60
  end

end
