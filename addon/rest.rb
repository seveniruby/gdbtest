
class RestAddon < GDBTestAddon
	def init
		require 'rubygems'
		require 'rest_client'
		require 'json'
		require 'cgi'
	end
	def do_start

	end
	def do_break(node)
		url='http://127.0.0.1:3000/'
		site = RestClient::Resource.new url
		data=[]
		node.each do |k,v|
			if ['code','thread','context','data','stack','eflags_ef'].index k.to_s
				data<<"node[#{k.to_s}]=#{CGI.escape(v.to_s)}"
			end
		end
		p data.join('&')
		p site['nodes.json'].post data.join('&')
		#p site['nodes.json'].post b.to_json :content_type => :json, :accept => :json
		#puts  RestClient.post url, {'code'=>'if   fff','stack'=>'test.cpp','thread'=>'2','context'=>'22','data'=>'33333'}.to_json
		#p RestClient.post url, {:Code=>'if   fff',:Stack=>'test.cpp',:Thread=>'2',:Context=>'22'}.to_json

		#RestClient.delete 'http://example.com/resource'
	end
	def register

	end
end
