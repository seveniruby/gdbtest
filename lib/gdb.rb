
class GDB
	attr_accessor :gdb
	def initialize(cmdline)
		if cmdline.index("gdb") 
			gdb=cmdline.split('--args')[0]
			exe=cmdline.split('--args')[-1].split[0]
			p "exe= #{exe}"
			args=cmdline.split('--args')[-1].split(exe)[1..-1].join(exe)
			p "args= #{args}"
			@gdb = IO.popen("#{gdb} #{exe}","r+")
			run "set args #{args}" if args
		else
			exe=cmdline.split[0]
			p "exe= #{exe}"
			args=cmdline.split(exe)[1..-1]
			args=args.join(exe) if args
			p "args= #{args}"
			@gdb = IO.popen("gdb -q --args "+exe,"r+")
			run "set args #{args}" if args
		end
		init
		read_to_prompt
	end
	def init
		run 'set logging file gdb.txt'
		run 'set logging on'
		run 'set logging overwrite on'
		run 'show logging'
		run 'set print null-stop'
		run 'set print array off'
		run 'set pagination off'
		#@g.run 'set scheduler-locking step'
		#@g.run 'set print elements 200'
		run 'handle SIGTERM nopass'
		run 'handle SIGHUP nopass'
		run 'set auto-solib-add'
		run 'set breakpoint pending on'
	end
	def kill()
		p @gdb.pid
		`kill -TERM #{@gdb.pid}`
	end
	def run(cmd)
		@gdb.puts(cmd.strip)
		read_to_prompt
	end
	def thread()
		run('thread')[0]
	end
	def thread_index()
		run('thread')[0].split[3]
	end
	def line(bt)
		bt[0].split(" at ")[-1]
	end

	def line_context(context)
		msg.join.split(' at ')[-1].split[0]
	end

	def eflags_ef
		ef=run('p ($eflags >> 7) & 1')[0].split[-1]
		ef
	end

	def bt()
		msg=run 'bt'
		s=[]
		msg.join().split("\n#").each do |line|
			if line.index " at "
				if line.index("#")==0
					s<<line.strip
				else
					s<<"\n#"+line.strip
				end	
			end
		end
		s
	end

	def stack(bt)
		s=[]
		bt.each do |line|
			line.gsub! "\n",''
			line.gsub! "\r",''
			s<<line.split(" at ")[-1].strip if line.index " at "
		end
		s
	end
	
	def function()
	end

	def args
	end

	def exit?(bt=nil)
		bt=run 'bt' if bt==nil
		return true if bt==[] || bt==nil
		#jruby bug
		return true if bt[0][0..0]!='#'
		return false
	end
	def read_to_prompt
		lines = []
		line = ""
		while result = IO.select([@gdb])
			next if result.empty?
			c = @gdb.read(1)
			break if c.nil?
			line << c
			break if line == "(gdb) " || line == " >"
			if line[-1] == ?\n
				lines << line
				line = ""
			end
		end
		puts lines.map { |l| "> #{l}" } if $gdb_verbose
		lines

	end
end


if __FILE__ == $0
	cmdline="a.exe"
	p cmdline
	GDB.new cmdline
	cmdline="a.exe < xxx"
	p cmdline
	GDB.new cmdline
	cmdline="a.exe < xxx > fffff"
	p cmdline
	GDB.new cmdline
	cmdline="gdb --args a.exe < xxx"
	p cmdline
	GDB.new cmdline
	cmdline="gdb --dir . --args a.exe < xxx"
	p cmdline
	GDB.new cmdline
end

