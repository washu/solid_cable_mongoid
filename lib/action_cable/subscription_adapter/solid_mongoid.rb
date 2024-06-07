# frozen_string_literal: true

require "mongoid"
module ActionCable
  module SubscriptionAdapter
    # == Mongoid Adapter for Action Cable
    # This adapter is for ActionCable 6.0.0 and later. It uses the `Mongoid::Document` model to store subscriptions.
    # and to store teh messages themselves. The adapter will define a TTL index to auto reomove messages from the collection
    # as time expires. This allows for a CATCHUP feature to be implemented in the mplmentation, to playback missing messages
    # that meet the channel and subscription criteria.
    def initialize(*)
      super
      @listener = nil
      ::SolidCableMongoid::Message.create_indexes rescue nil
    end

    def broadcast(channel, payload)
      ::SolidCableMongoid::Message.create!(channel: channel, message: payload.to_s, expiry: SolidCableMongoidexpiration.seconds.from_now)
    end

    def subscribe(channel, callback, success_callback = nil)
      listener.add_subscriber(channel_identifier(channel), callback, success_callback)
    end

    def unsubscribe(channel, callback)
      listener.remove_subscriber(channel_identifier(channel), callback)
    end

    def shutdown
      listener.shutdown
    end

    private

    def channel_identifier(channel)
      channel.size > 63 ? OpenSSL::Digest::SHA1.hexdigest(channel) : channel
    end

    def listener
      @listener || @server.mutex.synchronize { @listener ||= Listener.new(self, @server.event_loop) }
    end

    class Listener < SubscriberMap
      def initialize(adapter, event_loop)
        super()

        @adapter = adapter
        @event_loop = event_loop
        @queue = Queue.new

        @thread = Thread.new do
          Thread.current.abort_on_exception = true
          listen
        end
      end

      def listen
        resume_token = nil
        pipeline = [{ '$match' => { 'operationType' => 'insert' } }]
        # extra_pipeline = {'$match' => { 'fullDocument.channel' => {'$in': @subscribers.keys} }}
        fline = pipeline
        fline << { '$match' => { 'fullDocument.channel' => { '$in': @subscribers.keys } } }
        begin
          catch :shutdown do
            loop do
              until @queue.empty?
                action, channel, callback = @queue.pop(true)

                case action
                when :listen
                  # rebuild the filter
                  fline = pipeline
                  fline << { '$match' => { 'fullDocument.channel' => { '$in': @subscribers.keys } } }
                  @event_loop.post(&callback) if callback
                when :unlisten
                  # rebuild the filter
                  fline = pipeline
                  fline << { '$match' => { 'fullDocument.channel' => { '$in': @subscribers.keys } } }
                when :shutdown
                  throw :shutdown
                end
              end
              begin
                # we are going to use the resume token to keep track of where we are in the stream
                # we will use the max_await_time_ms to keep the stream from blocking indefinately
                # base on postrgesql adapter, so we can chanegt eh filtering aggregation to a match
                stream = ::SolidCableMongoid::Message.collection.watch(fline, resume_after: resume_token, max_await_time_ms: 1000)
                enum = stream.to_enum
                doc = ennum.try_next
                resume_token = stream.resume_token
                while doc do
                  channel = doc["fullDocument"]["channel"]
                  message = doc["fullDocument"]["message"]
                  broadcast(channel, message)
                  doc = enum.try_next
                  resume_token = stream.resume_token
                end
              rescue Mongo::Error
                # can be a tranient error, so try again. When rails shutdowns the shutdown will exit the loop.
                next
              end
            end
          end
        rescue
          # we are done with listen!
        end
      end

      def shutdown
        @queue.push([:shutdown])
        Thread.pass while @thread.alive?
      end

      def add_channel(channel, on_success)
        @queue.push([:listen, channel, on_success])
      end

      def remove_channel(channel)
        @queue.push([:unlisten, channel])
      end

      def invoke_callback(*)
        @event_loop.post { super }
      end
    end
  end
end
