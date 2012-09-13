require 'rubygems'
require 'tree'
require 'pp'
require 'csv'


class DataTree
	attr_accessor :root
	attr_accessor :rows
	attr_accessor :parent
	def initialize
		@root = Tree::TreeNode.new("Main", {:id=>0,
					   :index=>0,
					   :data=>'N', #断点数据
					   :stack_list=>"main",#堆栈函数列表
					   :break_point=>"",#断点值
					   :code=>"GDBTest",#断点处代码
					   :stack=>"main",#堆栈函数列表
					   :line_num=>"main",#行数
					   :thread=>"1",#线程数
					   :context=>"GDBTest",
					   :value=>"GdbTest, any problem please contact huangyansheng@baidu.com" })

		@parent={}
		@parent[@root[:thread]]=@root
		node_init @root
		@index=0
	end
	def node_init(current)
		current.content[:index]=0
		current.content[:data]='N'

	end
	def +(node)
		add(node[:id],node)
	end
	def add(key,value=nil)
		if value==nil
			value=key
			key=value[:id]
		end	
		@parent[value[:thread]]||=@parent[@root[:thread]]
		for p in @parent[value[:thread]].children||[]
			#same break_point after same parent, just merge
			#if p.content[:line_num]==value[:line_num]
			if p.content[:stack_list]==value[:stack_list] #&& p.content[:eflags_ef]==value[:eflags_ef]#&& p.content[:line_num]==value[:line_num]	#&& p.content[:thread]==value[:thread]		
				@parent[value[:thread]]=p
				@parent[value[:thread]].content[:index]+=1
				#把data添加到子节点列表中
				@index+=1

				return
			end
		end
		parents=[]
		parents = @parent[value[:thread]].parentage if @parent[value[:thread]].parentage!=nil
		parents << @parent[value[:thread]]
		for p in parents.reverse
			#not invoke, just a loop #&& p.parent.content[:code].index(/for|while/)!=nil
			#if p.content[:line_num]==value[:line_num]
			#只需堆栈相同就可以定位是否回环了。考虑到性能，允许去掉bt命令
			if p.content[:stack_list]==value[:stack_list] #&& p.content[:eflags_ef]==value[:eflags_ef]#&& p.content[:line_num]==value[:line_num] #&& p.content[:thread]==value[:thread]
				@parent[value[:thread]].content[:loop]=p.content[:id]
				@parent[value[:thread]]=p
				@parent[value[:thread]].content[:index]+=1
				#把data放到节点中
				@index+=1
				return
			end
		end



		current = Tree::TreeNode.new(key,value)
		node_init current

		@parent[value[:thread]].content[:index]+=1
		@parent[value[:thread]] << current

		@parent[value[:thread]] = current


	end
	#叶子节点不能衡量是一次完整的数据流，特定断点的回环才是真正的一条路径
	def leaf()
		index=0
		@root.each_leaf do |leaf|
			rows=[]
			keys=leaf.parentage.reverse.map {|x| x.content[:line_num]}
			keys<<leaf.content[:line_num]
			rows<<keys

			m=1
			n=keys.count-1
			CSV.open("#{ARGV[2]}_#{index}.csv", "w") do |csv|
				rows.each do |row|
					csv<<row
				end
			end
			index+=1

		end
	end
	def leaf_path
		rows=[]
		@root.each_leaf do |leaf|
			keys=leaf.parentage.reverse.map {|x| x.content[:line_num]}
			keys<<leaf.content[:line_num]
			rows<<keys
		end
		rows
	end

	#基于循环点回环的路径分析
	def path()
	end
	#dump出中间数据，供其他工具分析
	def dump()
	end
end

module Tree
	class TreeNode
		def mm(f,level = 0)
			return if level>200
			f.puts '<map version="0.9.0">' if is_root?
			f.print(' ' * level * 4)
			#.gsub("'",'&apos;').gsub('<','&lt;').gsub('>','&gt;')
			f.puts "<node id=\"#{content[:id]}\" stack_list=\"#{content[:stack_list].gsub('&','&amp;').gsub('"','&quot;')}\" text=\"#{content[:context].gsub('&','&amp;').gsub('"','&quot;')}\">"
			children { |child| child.mm(f,level + 1)}
			f.puts '<icon BUILTIN="clanbomber"/>' if children.size==1 && content[:branch]==true
			f.puts '<arrowlink DESTINATION="'+ "#{content[:loop]}" +'" ENDARROW="Default" ENDINCLINATION="628;0;" STARTARROW="None" STARTINCLINATION="628;0;"/>' if content[:loop]!=nil
			f.print(' ' * level * 4)
			f.puts "</node>"
			f.puts "</map>" if is_root?
		end
	end
end
