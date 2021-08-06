require 'sinatra'
require 'json'

configure do
@@i=0
@@habcolors = []
retry_count = 0
begin
#sleep 60
habfile = File.open("HAB-consumer.txt", 'r')
rescue Errno::ENOENT => e
  retry_count += 1
  sleep 10
  if retry_count > 5
    raise
  else
    retry
  end
end
habfile.each do |line|
  line.chomp
  @@habcolors << JSON.parse(line).to_json
end
end

before do
   content_type :json
   headers 'Access-Control-Allow-Origin' => '*',
            'Access-Control-Allow-Methods' => ['OPTIONS', 'GET', 'POST']
end

#  get '/stream' do
#    return @@habcolors[@@i]
#    @@i=@@i+1
#end
##  { :hab1color => '#00FF00', :hab2color => '#00FF00' }.to_json

class Cache
  @@count = 0

  def self.init()
   @@count = 0
  end

  def self.increment()
    @@count = @@count + 1
  end

  def self.count()
    return @@count
  end
end

configure do
  Cache::init()
end

get '/stream' do
if Cache::count() == 0
    Cache::increment()
   puts @@habcolors[Cache::count-1]
   @@habcolors[Cache::count-1]
 else
    Cache::increment()
   puts @@habcolors[Cache::count-1]
   @@habcolors[Cache::count-1]
end
end
