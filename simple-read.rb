require 'json'

hab1colors = File.open("HAB-consumer1.txt", 'r')
hab1colors.each do |line|
  line.chomp
  puts JSON.parse(line)
end


