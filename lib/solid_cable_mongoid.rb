# frozen_string_literal: true

require "solid_cable_mongoid/version"
require "solid_cable_mongoid/engine"
require "action_cable/subscription_adapter/solid_mongoid"

module SolidCableMongoid
  class Error < StandardError; end
  def cable_config
    Rails.application.config_for('cable')
  end
  def collection_prefix
    cable_config.collection_prefix || 'solid_cable_'
  end

  def use_default?
    cable_config.client.blank?
  end

  def db_client
    cable_config.client || :default
  end

  def expiration
    cable_config.expiration || 60
  end

end
