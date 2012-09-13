class GDBTestAddon 
	#@gdbtest为gdbtest的对象，可以调用他的公共方法
	#@param为gdbtest的param参数对象
	def initialize
		@gdbtest=$gdbtest
		@param=$param
		@log=$gdbtest.log
	end
	def parse(opts,param)
		opts.on("-test", "--addontest line", "run cmd when function or line") do |v|
			param[:addontest] = v
		end
	end


	def init
	end
	#gdb的初始化
	def gdb_init
	end

	#node包含断点处的信息，包含输出，breakpoint，code
	def do_break(node)
	end
	#结束时保存数据
	def report
	end	
	def method_missing(method,*args)
		p "#{method} not define"
	end	
end
