

class DiffAddon < GDBTestAddon
	def init
		@diff_tree=DataTree.new
	end
	def parse(opts,param)
		opts.on("", "--old file", "old version of gdbtest.yaml") do |v|
			param[:old] = v
		end
		opts.on("", "--new file", "new version of gdbtest.yaml") do |v|
			param[:new] = v
		end
		opts.on("", "--diff ", "export diff tree") do |v|
			param[:diff] = v
		end
	end
	def report
		diff
	end
	def diff
		@diff={}
		@old=@gdbtest.load @param[:old]
		@new=@gdbtest.load @param[:new]
		@old.each do |k,v|
			code_old=v[0].map{|x| x[:code]}
			code_new=@new[k][0].map{|x| x[:code]}
			if code_old==code_new
				next
			else
				@diff[k]||={}
				@diff[k][:old]=v
				@diff[k][:new]=@new[k]
				if @param[:diff]
					@diff_tree.parent["old"]=@diff_tree.root
					node={:id=>k,:stack_list=>k,:thread=>k,:code=>k,:context=>k}
					@diff_tree+ node
					parent=@diff_tree.parent[k]
					v[0].map {|node| node[:id]="old_#{node[:id]}";node[:loop]&&="old_#{node[:loop]}" ;node[:stack_list]+="old";node[:thread]=k;@diff_tree.add "old_#{node[:id]}",node}
					@diff_tree.parent[k]=parent
					@new[k][0].map {|node| node[:id]="new_#{node[:id]}";node[:loop]&&="new_#{node[:loop]}" ;node[:stack_list]+="new";node[:thread]=k;@diff_tree.add "new_#{node[:id]}",node}
				end
			end
		end
		p "count of old: #{@old.size}"
		p "count of new: #{@new.size}"
		p "Diff count: #{@diff.size}"
		p "Diff rate: #{@diff.size.to_f*100/@old.size}%"
		@gdbtest.dump @diff, "#{@gdbtest.dir_base}/old_new.diff"
		p "Diff File:  #{@gdbtest.dir_base}/old_new.diff"
		File.open("#{@gdbtest.dir_base}/old_new.mm",'w') do |ff|
			@diff_tree.root.mm ff
		end
	end
end
DiffAddon.new
