class GDBTestAddon 
	#@gdbtestΪgdbtest�Ķ��󣬿��Ե������Ĺ�������
	#@paramΪgdbtest��param��������
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
	#gdb�ĳ�ʼ��
	def gdb_init
	end

	#node�����ϵ㴦����Ϣ�����������breakpoint��code
	def do_break(node)
	end
	#����ʱ��������
	def report
	end	
	def method_missing(method,*args)
		p "#{method} not define"
	end	
end
