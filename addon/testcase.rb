
class TestCaseAddon < GDBTestAddon
	def init
		@session=@gdbtest.session
		@session=@gdbtest.load(@param[:path]) if @param[:path]
		@paths={}
		@param[:tc_start]||=@param[:key]
	end
	def parse(opts,param)
		opts.on("", "--tc_start line", "run cmd when function or line") do |v|
			param[:tc_start] = v
		end
		opts.on("", "--tc_end line", "run cmd when function or line") do |v|
			param[:tc_end] = v
		end
		opts.on("-v", "--var 'info args'", "run cmd when function or line") do |v|
			param[:var] = v
		end
		opts.on("-k", "--key function", "the key function to split tc with tc") do |v|
			param[:key] = v
		end


	end
	def do_break(node)
		@node=node
		tcs(node)
	end
	def report
		@gdbtest.dump @gdbtest.tc.tcs,'gdbtest/gdbtest.tcs'
		puts "TC groups: gdbtest/gdbtest.tcs"

	end

	def do_stop(node)
		#@gdbtest.dump @gdbtest.tc.get_tc(node),"gdbtest/tc.#{@gdbtest.tc.get_index(node)}.tc"
	end


	def tcs(node)
		return if @gdbtest.param[:key]==nil
		return if !@gdbtest.tc.exist?
		#return if @gdbtest.param[:code]==[]
		line=node[:function]
		if line=~/#{@param[:tc_start]}/ || @gdbtest.tc.mark=='start'
			@gdbtest.tc.create node		
			if @gdbtest.config[:addon]["gcov"]
				@gdbtest.config[:addon]["gcov"].tc_start
			end	
		end
		return if !@gdbtest.tc.thread_exit?(node)
		return if !@gdbtest.tc.in?(node)
		if line=~/#{@param[:tc_end]}/  || @gdbtest.tc.mark=='stop'
			if @gdbtest.config[:addon]["gcov"]
				@gdbtest.config[:addon]["gcov"].tc_end
				@gdbtest.tc.path_set node,@gdbtest.config[:addon]["gcov"].tc_path_get
			end
			@gdbtest.dump @gdbtest.tc.get_tc(node),"gdbtest/tc.#{@gdbtest.tc.get_index(node)}.tc"
			@gdbtest.tc.close node 
		end
		regexp_key=Regexp.new "#{@gdbtest.param[:key]}"
		if line=~regexp_key 
			if @gdbtest.param[:var]
				data=@gdbtest.g.run(@gdbtest.param[:var]).join
				@gdbtest.tc.data_set data	
			end
		end

		@gdbtest.tc.path_add node
	end
end
