
class MemAddon < GDBTestAddon
	def init
		require 'yaml'
		@file_mark="mem.cmd"
		@file_path="mem.path"
		@path=[]
		@stop=true
	end
	def do_start

	end
	def do_break(node)
		return if !File.exist? @file_mark
		mark=IO.read(@file_mark) 
		if mark.index("start") && @stop==true
			puts "tc path record"
			@stop=false
		end
		if mark.index("stop") && @stop==false
			puts "tc path save"
			@stop=true
			@gdbtest.dump @path,@file_path
			@path=[]
		end
		if @stop==false
			#@path<<{:line=>node[:stack],:context=>node[:context]}
			@path<<node[:stack].split[-1]
			@gdbtest.dump @path,@file_path
		end
	end
end
