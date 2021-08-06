require "logger"
require "pg"
require "redis"
require "sequel"

puts "I saw env in #{ENV["DATABASE_URL"]}"
#DB = Sequel.connect(ENV["DATABASE_URL"] || abort("need DATABASE_URL"))
DB = Sequel.connect("postgres://admin:admin@127.0.0.1:5432/chefconf2018demo")
DB.extension :pg_json

#RDB = Redis.new(url: ENV["REDIS_URL"] || abort("need REDIS_URL"))
RDB = Redis.new(url: "redis://127.0.0.1:6379/0")
puts "I saw rdb in #{RDB}"

STREAM_NAME = ENV["STREAM_NAME"] || "rocket-rides-log"
STREAM_MAXLEN = 10000

# a verbose mode to help with debugging
if ENV["VERBOSE"] == "true"
  DB.loggers << Logger.new($stdout)
end
