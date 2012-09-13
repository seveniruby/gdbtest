

require 'rubygems'
require 'webrick'

class WebAddon < GDBTestAddon
	def init
		server = WEBrick::HTTPServer.new(:Port=>7777)
		server.mount_proc '/tc' do |req, res|
			tc(req.query["mark"])
			res.status = 200
			res['Content-Type'] = "text/plain"
			res.body = 'Hello, world!'
		end

		Thread.new do 
			server.start 
		end
	end
	def tc(method)
		p method
		@gdbtest.tc.mark=method
	end
end
