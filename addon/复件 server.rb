

require 'rubygems'
require 'webrick'

class ServertAddon < GDBTestAddon
	def init
		server = WEBrick::HTTPServer.new
		server.mount_proc '/tc' do |req, res|
			p 'ddddd'
			res.status = 200
			res['Content-Type'] = "text/plain"
			res.body = 'Hello, world!'
		end

		server.start
	end
end
