# frozen_string_literal: true

require "test_helper"
require "mongoid"
require_relative '../lib/app/models/solid_cable_mongoid/message'
class TestSolidCableMongoid < Minitest::Test
  def setup
    Mongoid.configure do |config|
      config.clients.default = {
        hosts: ['Mac-Studio.local:27017?replicaSet=dbrs'],
        database: 'test',
      }
    end
    ::SolidCableMongoid::Message.create_indexes rescue nil
    ::SolidCableMongoid::Message.delete_all
  end
  def test_that_it_has_a_version_number
    refute_nil ::SolidCableMongoid::VERSION
  end

  def log(message)
    puts message
  end

  def test_it_does_something_useful
    server = ActionCable::Server::Base.new
    sub_adapter = ActionCable::SubscriptionAdapter::SolidMongoid.new(server)
    cnt = 1
    sub_adapter.subscribe('test', ->(message) { puts message;cnt += 1})
    sleep 1
    1_000.times do |i|
      sub_adapter.broadcast('test', "Hello World #{i}")
    end
    puts cnt
    assert cnt == 1_000
  end
end
