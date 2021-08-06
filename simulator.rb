require "net/http"
require "securerandom"

require_relative "./api"

class Simulator
  def initialize(port:)
    self.port = port
  end

  def run
count=1
    loop do
#     50.times do
      run_once
      if count<10
        duration = rand * 2
      else
        duration=600
      end
#      duration = rand(0.001..0.003)
      $stdout.puts "Sleeping for #{duration}"
      sleep(duration)
      count+=1
    end
  end

  def run_once
    http = Net::HTTP.new("localhost", port)
    request = Net::HTTP::Post.new("/rides")
    distance = "#%02x%02x%02x" % [rand(MIN_COLOR..MAX_COLOR),rand(MIN_COLOR..MAX_COLOR) ,rand(MIN_COLOR..MAX_COLOR) ]
    distance.upcase!
    request.set_form_data({
      #"color" => rand * (MAX_COLOR - MIN_COLOR) + MIN_COLOR
      "distance" => distance
    })

    response = http.request(request)
    $stdout.puts "Response: status=#{response.code} body=#{response.body}"
  end

  #
  # private
  #

  MAX_COLOR = 255
  private_constant :MAX_COLOR
  MIN_COLOR = 1
  private_constant :MIN_COLOR

  attr_accessor :port
end

#
# run
#

if __FILE__ == $0
  # so output appears in Forego
  $stderr.sync = true
  $stdout.sync = true

  port = ENV["API_PORT"] || abort("need API_PORT")

  # wait a moment for the API to come up
  sleep(3)

  Simulator.new(port: port).run
end
