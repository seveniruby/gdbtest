require 'tree'

class FreeMindAddon < GDBTestAddon
	def init
		@code_tree=@gdbtest.code_tree
		if @param[:start]==nil
			@record=true
		else
			@record=false
		end
		@code_tree=@gdbtest.load(@param[:tree]) if @param[:tree]
		@regexp_if=Regexp.new(' *if *\(')
		@regexp_loop=Regexp.new('\belse\b|\bfor *\(|\bwhile *\(')
	end
	def parse(opts,param)
		opts.on("","--limit number","limit the times of some breakpoint") do |v|
			param[:limit]=v.to_i
		end
		opts.on("","--window number","the distance of one breakpoint with different time") do |v|
			param[:window]=v.to_i
		end
		
	end
	def breaks_get
		
	end


	def do_break(node)
		record(node)
		skip(node)
		#skip_auto(node)
	end
	
	def record(node)
		@node=node
		bt=node[:stack].split
		if @record==false 
			@gdbtest.log.debug 'record check'
			@gdbtest.log.debug bt
			if bt[-1]=~/#{@param[:start]}/ && @param[:start]!=nil
				@gdbtest.log.debug "record start"
				@record=true
			else
				breakpoint=node[:break_point]
				p "delete #{breakpoint}"
				@gdbtest.g.run "delete #{breakpoint}"

			end
		end

		if @record==true
			#if @node[:branch]
			#        node_base=@node.clone	
			#	node_base[:eflags_ef]=''
			#	#@code_tree.add node_base[:id],node_base 
			#end
			#@node[:context]=@node[:eflags_ef]+" "+@node[:context]
			#@node[:stack]=@node[:stack]+" "+@node[:eflags_ef]
			@code_tree.add @node[:id],@node 
			size=@code_tree.root.size
			#mm 
		end
	end

	def skip(node)
		@node=node
		bt=node[:stack]
		msg=node[:code]

		return if @param[:skip]==nil
		if bt[0]=~/#{@param[:skip]}/ && @param[:skip]!=nil
			breakpoint=msg.split(',')[0]
			p "delete #{breakpoint}"
			@gdbtest.g.run "delete #{breakpoint}"

		end
	end
	def skip_auto(node)
		@param[:limit]||=100
		@param[:window]||=5
		@record_run||={}
		@before_run||={}
		@index||=0
		@index+=1
		@record_run[node[:break_point]]||=0
		@record_run[node[:break_point]]+=1
		#if some breakpoint run many time repeatedly, should be remove
		@log.debug "record_run[#{node[:break_point]}]=#{@record_run[node[:break_point]]}"
		@log.debug "before_run[#{node[:break_point]}]=#{@before_run[node[:break_point]]}"
		if @record_run[node[:break_point]]>@param[:limit] and (@index-@before_run[node[:break_point]])<@param[:window]
			@gdbtest.g.run "delete #{node[:break_point]}" 
		end
		@before_run[node[:break_point]]=@index

	end
	def mm()
		return if @code_tree==nil || @last_save==@code_tree.root.size
		file="#{@gdbtest.dir_base}/gdbtest.mm"
		File.open(file,"w") do |f|
			@code_tree.root.mm f
			@last_save=@code_tree.root.size
		end
		@gdbtest.dump @code_tree,"#{@gdbtest.dir_base}/gdbtest.yaml"
	end

	def coverage
		return if @code_tree==nil
		if_count=0
		path_count=0
		@code_tree.root.each do |node|
			if @regexp_if=~node.content[:code]#.force_encoding('ISO-8859-1').encode('UTF-8',:undef=>:replace,:invalid=>:replace,:replace=>nil)
				if_count+=2
				path_count+=node.children.size
			end			
		end
		p "if count=#{if_count}"
		p "if hit=#{path_count}"
		p "if coverage=#{path_count.to_f*100/if_count}%" if if_count!=0

	end
	def path_miss
		return if @code_tree==nil
		paths_miss=[]
		paths_hit=[]
		@code_tree.root.each_leaf do |leaf|
			path_miss=[]
			leaf.parentage.reverse.each do |node|
				path_miss<<node.content[:line_num]
				if node.children.size==1 && @regexp_if=~node.content[:code]#.force_encoding('ISO-8859-1').encode('UTF-8',:undef=>:replace,:invalid=>:replace,:replace=>nil)
					paths_miss << path_miss.clone 
				end
			end
			paths_hit<<path_miss.clone
		end
		p "path hit=#{paths_hit.size}"
		p "path miss=#{paths_miss.size}"
		p "path coverage=#{paths_hit.size*100.to_f/(paths_hit.size+paths_miss.size)}%" if (paths_hit.size+paths_miss.size)!=0
		@gdbtest.dump paths_miss,"#{@gdbtest.dir_base}/gdbtest.miss"
		p "#{@gdbtest.dir_base}/gdbtest.miss: paths missed"
		@gdbtest.dump paths_hit,"#{@gdbtest.dir_base}/gdbtest.hit"
		p "#{@gdbtest.dir_base}/gdbtest.hit paths hit"
	end

	def report
		return if @gdbtest.code_tree==nil || @gdbtest.code_tree.root.size==1
		@gdbtest.dump @record_run,"#{@gdbtest.dir_base}/breaks.run"
		mm
		coverage
		path_miss
	end
end
