
class TcPathAddon < GDBTestAddon
	def init
		require 'yaml'
		@file_mark="tcpath.cmd"
		@file_path="tcpath.path"
		@file_tc="tc.data"
		@file_tcpath="tcpath.data"
		@file_pathtc="pathtc.data"
		@path=[]
		@stop=true
		@tc_path={}
		@path_tc={}
		@tc_count=0
	end
	def do_start

	end

	def do_break(node)
		return if !File.exist? @file_tc
		data=IO.read(@file_tc)
		if @last!=data
			@tc_count+=1
			@tc_path[data]=[]
			@path_tc[@tc_path[@last]]||=[]
			@path_tc[@tc_path[@last]]<<@last
			@gdbtest.dump @tc_path,@file_tcpath
			@gdbtest.dump @path_tc,@file_pathtc

			if @tc_path[@last]
				@gdbtest.dump @tc_path[@last],"tc.#{@tc_count}.path"
				@gdbtest.dump @tc_path[@last].uniq,"tc.#{@tc_count}.path.uniq"
			end
			@last=data
		else
			@tc_path[data]<<node[:line]
		end
	end
	def report
	end
end
