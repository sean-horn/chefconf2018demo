require_relative "./api"
require "pry"

class Consumer

  # Increments a Redis stream ID. If we want to start reading a stream from
  # after some ID we know about we need to increment the ID ourselves and ask
  # Redis for the results from there.
  def self.increment(id)
    # IDs are of the form "1509473251518-0" and comprise a millisecond
    # timestamp plus a sequence number to differentiate within the timestamp.
    time, sequence = id.split("-")
    raise ArgumentError, "Expected ID to contain sequence" if sequence.nil?
    next_sequence = Integer(sequence) + 1
    "#{time}-#{next_sequence}"
  end

  def initialize(name:)
    self.name = name
@f = File.open("HAB-consumer.txt", 'a')
  end

  def run
    $stdout.puts "Starting consumer: #{name}"

    loop do
      begin
        # simulate a consumer crash some amount of the time
        #num_consumed = run_once(simulate_crash: rand() < 0.10)
        num_consumed = run_once(simulate_crash: rand() < 0.20)

        # Sleep for a while if we didn't find anything to consume on the last
        # run.
        if num_consumed == 0
          $stdout.puts "Sleeping for #{SLEEP_DURATION}"
          sleep(SLEEP_DURATION)
        end

      rescue SimulatedCrashError
        $stdout.puts "Crash simulated! Records consumed but transaction aborted."
      end
    end
  end

  def run_once(simulate_crash: false)
    num_consumed = 0

    DB.transaction do
      checkpoint = Checkpoint.first(name: name)

      # "-" is a special symbol in Redis streams that dictates that we should
      # start from the earliest record in the stream. If we don't already have
      # a checkpoint, we start with that.
      start_id = "-"
      start_id = self.class.increment(checkpoint.last_redis_id) unless checkpoint.nil?

      checkpoint = Checkpoint.new(name: name, last_ride_id: 0) if checkpoint.nil?
#puts "I got checkpoint #{checkpoint.last_ride_id}"

      records = RDB.xrange(STREAM_NAME, start_id, "+", "COUNT", BATCH_SIZE)
 #puts "I got records #{records}"
      unless records.empty?
        # get or create a new state for this consumer
        state = ConsumerState.first(name: name)
        state = ConsumerState.new(name: name, color: '') if state.nil?

        records.each do |record|
          redis_id, fields = record

          # ["data", "{\"id\":123}"] -> {"data"=>"{\"id\":123}"}
          fields = Hash[*fields]

#puts "I got rfields #{fields['data']}"
          data = JSON.parse(fields["data"])
#puts "I got data #{data}"


          # if the ride's ID is lower or equal to one that we know we consumed,
          # skip it; this is a double send
          if data["id"] <= checkpoint.last_ride_id
            $stdout.puts "Skipped record: #{fields["data"]} " \
              "(already consumed this habicat color ID)"
            next
          end

#	  #data["distance"].match /#(..)(..)(..)/
#r = ($1.hex + 1 <= 255 ? $1.hex + 1 : 255)
#g = ($2.hex + 1 <= 255 ? $2.hex + 1 : 255)
#b = ($3.hex + 1 <= 255 ? $3.hex + 1 : 255)
#color = "#%02x%02x%02x" % [r,g,b]
#data["distance"] = color.upcase
          state.color = data["distance"]
          

          $stdout.puts "Consumed record: #{fields["data"]} " \
            "color=#{state.color}"
#write the clean stream to a file per consumer
unless simulate_crash
  @f.write "{\"hab#{name[-1]}_id\": #{data["id"]}, \"hab#{name[-1]}_color\":\"#{data["distance"]}\"}\n" 
end
          num_consumed += 1

          checkpoint.last_redis_id = redis_id
          checkpoint.last_ride_id = data["id"]
        end

        # now that all records for this round are consumed, persist state
        state.save

        # and persist the changes to the checkpoint
        checkpoint.save

        raise SimulatedCrashError if simulate_crash
      end
    end

    num_consumed
  end

  private

  class SimulatedCrashError < StandardError
  end

  # Number of records to try to consume on each batch.
  BATCH_SIZE = 20
  private_constant :BATCH_SIZE

  # Sleep duration in seconds to sleep in case we ran but didn't find anything
  # to stream.
  SLEEP_DURATION = 2
  private_constant :SLEEP_DURATION

  attr_accessor :name
end

#
# run
#

if __FILE__ == $0
  # so output appears in Forego
  $stderr.sync = true
  $stdout.sync = true

  name = ARGV[0] || abort("Usage: ruby consumer.rb CONSUMER_NAME")

f = File.open("HAB-consumer.txt", 'a')
#f.write "{\"colors\": {\n" 
#f.close
  Consumer.new(name: name).run
#f.write "}" 
#f.close
end
