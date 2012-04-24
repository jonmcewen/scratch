require 'logger'
require 'net/http'

log = Logger.new(STDOUT)
log.level = Logger::INFO
debug = false
if ARGV.include? '-debug'
	debug = true
	log.level = Logger::DEBUG
	ARGV.shift
end

print "Enter site names, one per line, then -1 to start processing\n"

# Get sites list from standard input

pages = []
page = gets.chomp
until page == "-1"
	pages << page
	page = gets.chomp 
end

# Do GETs and find sizes
log.debug "Getting pages:\n#{pages.join("\n")}\n"

threads = []
results = []

for page in pages
	threads << Thread.new(page) { |myPage|

	h = Net::HTTP.new(myPage)
	if debug 
		h.set_debug_output($stdout)
	end
	h.read_timeout = 1.5 # in seconds
	log.debug "Fetching: #{myPage}"
	begin
		resp, data = h.get('/')
		log.debug "Got #{myPage}:  #{resp.message}"

		case resp
		when Net::HTTPOK
			log.debug "OK"
			results << myPage + " " + resp.body.size.to_s
		
		else
			log.debug "NOT OK: #{resp}"
			results << myPage + " *"
		end
	rescue => e
		log.debug e.message
		results << myPage + " *"
	end
  }
end


threads.each { |aThread|  aThread.join }

puts "\nResults:\n\n"
puts results.join("\n")
puts "-1"
