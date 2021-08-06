require "json"
require "sinatra"

require_relative "./config"

class API < Sinatra::Base
  set :server, %w[puma]
  set :show_exceptions, false

  post "/rides" do
    params = validate_params(request)

    DB.transaction(isolation: :serializable) do
      ride = Ride.create(
        distance: params["distance"]
      )

      StagedLogRecord.insert(
        action: ACTION_CREATE,
        object: OBJECT_RIDE,
        data: Sequel.pg_jsonb({
          id:       ride.id,
          distance: ride.distance,
        })
      )

      [201, JSON.generate(wrap_ok(
        Messages.ok(distance: params["distance"])
      ))]
    end
  end
end

#
# constants
#

ACTION_CREATE = "create"
ACTION_UPDATE = "update"
ACTION_DELETE = "delete"

OBJECT_RIDE = "habicat"

#
# models
#

class ConsumerState < Sequel::Model
end

class Ride < Sequel::Model
end

class Checkpoint < Sequel::Model
end

class StagedLogRecord < Sequel::Model
end

#
# other modules/classes
#

module Messages
  def self.error_require_text(key:)
    "Parameter '#{key}' must be text."
  end

  def self.error_require_param(key:)
    "Please specify parameter '#{key}'."
  end

  def self.ok(distance:)
    "Color accepted. Your habicat will be=#{distance}"
  end
end

#
# helpers
#

def validate_params(request)
  {
    "color" => validate_params_text(request, "color"),
  }
end

def validate_params_text(request, key)
  val = validate_params_present(request, key)

  # Float as opposed to to_f because it's more strict about what it'll take.
  begin
    Text(val)
  rescue ArgumentError
    halt 422, JSON.generate(wrap_error(Messages.error_require_text(key: key)))
  end
end

def validate_params_present(request, key)
  val = request.POST[key]
  return val if !val.nil? && !val.empty?
  halt 422, JSON.generate(wrap_error(Messages.error_require_param(key: key)))
end

# Wraps a message in the standard structure that we send back for error
# responses from the API. Still needs to be JSON-encoded before transmission.
def wrap_error(message)
  { error: message }
end

# Wraps a message in the standard structure that we send back for success
# responses from the API. Still needs to be JSON-encoded before transmission.
def wrap_ok(message)
  { message: message }
end

#
# run
#

if __FILE__ == $0
  port = ENV["API_PORT"] || abort("need API_PORT")
  API.run!(port: port)
end
