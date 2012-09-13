#coding: utf-8

root=File.dirname(File.dirname(__FILE__))
$: << "#{root}/lib"
require 'rubygems'
#require 'bundler/setup'
require 'yaml'
require 'optparse'
require 'digest/md5' 
require 'pp'
require 'logger'
require 'benchmark'

$log=Logger.new(STDOUT)
$log.level=Logger::INFO

class String
	def to_u(encoding)
		#jruby1.6 bug , only for 1.7
		self.force_encoding(encoding).encode('UTF-8',:undef=>:replace,:invalid=>:replace,:replace=>nil)
	end
end
class GDBTest
	attr_accessor :g
	attr_accessor :param
	#断点列表
	attr_accessor :breaks
	#源文件列表
	attr_accessor :sources 
	attr_accessor :code_tree 
	attr_accessor :session
	attr_accessor :tc
	attr_accessor :path_tc
	attr_accessor :file_sources
	attr_accessor :file_breaks
	attr_accessor :dir_base
	attr_accessor :id 
	attr_accessor :node_old 
	attr_accessor :node
	attr_accessor :log
	attr_accessor :config
	def initialize
		if $log
			@log=$log
		else
			@log=Logger.new(STDOUT) 
		end
		@config={}
		@config[:addon]={}
	end
	def parse(param={})
		@param=param
		@addons=@config[:addon].values
		@dir_base='gdbtest'
		`mkdir #{@dir_base}`
		@file_sources="#{@dir_base}/gdbtest.file"
		@file_breaks="#{@dir_base}/gdbtest.break"
		if @param[:level]
			eval "@log.level=Logger::#{@param[:level]}" 
		else
			@log.level=Logger::INFO 
		end
		@log.debug @param
		if @param[:start]==nil
			@record=true
		else
			@record=false
		end
		if @param[:dir]
			@dir=File.expand_path(@param[:dir])
		else
			@dir=File.expand_path(".")
		end
		@param[:code]||="branch"
		@log.debug @dir

		@regexp_line=Regexp.new('.*')
		@regexp_if=Regexp.new(' *if *\(|\belse\b')
		@regexp_loop=Regexp.new('\bfor *\(|\bwhile *\(')
		#didn't use the info functions, because it's output too much content, and maybe break on the sytem lib
		@regexp_function=Regexp.new('\b [a-zA-Z][a-zA-Z0-9_]*\(.*\)$')
		@regexp_mem=Regexp.new('=.*malloc\(|\bfree\(|=.*new |\bdelete |delete\[\] ')
		#@regexp_mem=Regexp.new('=.*malloc\(|\bfree\(|=.*new |\bdelete |delete\[\] |\.push_back\(.*\)|\.insert\(.*\)|\.append\(.*\)|\.clear\(\)')

		@code_tree=DataTree.new
		@tc=TestCase.new
		@session={}
		@path_tc=[]
		#addon执行初始化
		gdb_init
		init
		run
		report
	end
	def dump(obj,file)
		tmp=file+".tmp"
		File.open(tmp,'w') do |f|
			YAML.dump(obj,f)
		end
		File.rename tmp,file
	end
	def load(file)
		YAML.load(File.open(file))
	end

	def init
		@addons.map {|x| p x.class;x.send __method__ }
	end
	def gdb_init
		return if @param[:gdb]==nil
		@g=GDB.new @param[:gdb]
	end
	def branch?(code)
		return true if @regexp_if=~code	
		return false
	end

	def sources_get
		@sources=[]
		return if @g==nil
		if @param[:files]==nil
			@g.run('info sources').join.split(/\n|,/).each do |line|
				line.strip!
				@log.debug line
				if File.exist?(line) && File.expand_path(line)=~/#{@dir}/
					@sources<<line 
					puts "Analyse From #{line}"
					@log.debug "add #{line}"
				end
			end
			dump(@sources,@file_sources)
		else
			@sources=load @file_sources
		end

	end

	def functions_get
		@log.debug __method__
	end
	def breaks_get()
		@log.debug __method__
		return if @g==nil
		@breaks=[]
		@breaks<< { :line=>@param[:key], :code=>"" } if @param[:key]
		@breaks<< { :line=>@param[:tc_start], :code=>"" } if @param[:tc_start]
		@breaks<< { :line=>@param[:tc_end], :code=>"" } if @param[:tc_end]
		@breaks<< { :line=>@param[:start], :code=>"" } if @param[:start]
		if @param[:code]
			@log.debug "--code #{@param[:code]}"
			@sources.each do |file|
				lines=IO.readlines(file)
				lines.each_index do |i|
					if @param[:code].index "branch"
						#=~// bug
						if @regexp_if=~lines[i]
							@breaks<< { :line=>"#{file}:#{i+1}",:code=>lines[i] }
							@breaks<< { :line=>"#{file}:#{i+2}",:code=>lines[i+1] }
						end
					end
					if @param[:code].index 'loop'
						if @regexp_loop=~lines[i]
							@breaks<< { :line=>"#{file}:#{i+1}",:code=>lines[i] }
						end
					end
					if @param[:code].index 'function'
						if @regexp_function=~lines[i] && lines[i].index('if(')==nil
							@breaks<< { :line=>"#{file}:#{i+1}",:code=>lines[i] }
						end
					end
					if @param[:code].index 'mem'
						if @regexp_mem=~lines[i]
							@breaks<< { :line=>"#{file}:#{i+1}",:code=>lines[i] }
						end
					end
					if @param[:code].index 'line'
						if @regexp_line=~lines[i]
							@breaks<< { :line=>"#{file}:#{i+1}",:code=>lines[i] }
						end
					end

				end
			end
		end
		#thanks for liujing to find a bug in here
		#@breaks=load @file_breaks if @param[:break]
		@breaks=load @param[:break] if @param[:break]
		@addons.map {|x| x.send __method__ }
		dump @breaks,@file_breaks
	end

	def breaks_set()
		@log.debug __method__
		return if @g==nil
		@breaks.each do |b|
			msg=@g.run "b #{b[:line]}"
		end
	end

	def do_break(msg)
		@log.debug __method__
		@addons.map {|x| x.send __method__,msg }
	end
	def do_stop(node)
		@addons.map {|x| x.send __method__,node}
	end
	def do_start
		@log.debug __method__
		sources_get
		breaks_get
		breaks_set
		@addons.map {|x| x.send __method__}
	end
	def do_end
		@addons.map {|x| x.send __method__,msg }
	end
	def run
		return if @g==nil
		@log.debug  "run"
		@id=0
		@node_old=@code_tree.root.content
		data='N'
		msg=@g.run "start"
		do_start
		bt=@g.bt
		@log.debug bt
		@interrupted = false	
		begin
			trap("INT") { @interrupted = true;@log.info  "ctrl+c"; raise }
			trap("KILL") { @interrupted = true;@log.info  "kill"; raise }
			trap("TERM") { @interrupted = true;@log.info  "term"; raise }
			@log.debug "exit?"
			@log.debug @g.run 'bt'
			@log.debug @g.exit?
			Benchmark.bm(7) do |x| 
				while !@g.exit?(bt) && @interrupted==false
					#line=@g.line bt
					puts msg
					thread=@g.thread
					stack=@g.stack(bt).reverse.join(" ")
					line=@g.line bt
					function=stack.split()[-1]
					res_if=""
					context=msg.join.split("\nBreakpoint ")[-1].to_u(@param[:encoding]||'ISO-8859-1') #.force_encoding('ISO-8859-1').encode('UTF-8',:undef=>:replace,:invalid=>:replace,:replace=>nil)
					code=context.split(/:[0-9]/)[-1].split[2..-1].join
					@node={
						:id=>@id+=1,
						:break_point=>context.split(',')[0],
						:context=>context,
						:code=>code,
						:data=>data,
						:thread=>thread,
						:stack=>stack,
						:line_num=>line,
						:line=>line,
						:branch=>branch?(code),
						:eflags_ef=>res_if,
						:function=>function,
						:stack_list=>stack
					}
					#@log.debug "EF"
					#@log.debug @g.eflags_ef
					#采用汇编判断结果，会有误差。if后面发生了堆栈变化，sf会被冲掉。对于循环，也是会有问题�?
					#
					#if @node[:branch]
					#	@g.run 'ni 5' 
					#	@g.run 'n' if !@node[:branch]
					if @g.eflags_ef=="0"
						res_if='T'
					else
						res_if="F"
					end
					#end
					@node[:eflags_ef]=res_if

					@log.debug @node.inspect
					#do your thing 
					time_break=Benchmark.measure('do_break') {
					do_break(@node)
					}
					@log.debug "do_break\t#{time_break}"
					time_c=Benchmark.measure('c') {
						msg=@g.run 'c'
					}
					@log.debug "c\t#{time_c}"
					time_bt=Benchmark.measure('bt') {
						bt=@g.bt
					}
					@log.debug "bt\t#{time_bt}"
					@node_old=@node.clone
					#@g.run @param[:breakcmd] if @param[:breakcmd]
				end
			end
			@log.debug "process end"
			@log.debug bt
		rescue Exception=>e
			puts e.message
			puts e.backtrace
			@g.kill
		end
		do_stop(@node)
	end

	#the new running style, don't use breakpoint
	def run2
	end

	def report
		@addons.map {|x| x.send __method__ }
	end

	def data_load
		@addons.map {|x| x.send __method__ }
	end
end

#jruby bug 
#if __FILE__ == $0
$param = {}
$addons=[]
$gdbtest=GDBTest.new

['addon','gdb', 'tree', 'mm','testcase'].each do |v|
	x=require "#{v}"
	$log.fatal "#{v} load error" if !x
end

Dir["#{root}/addon/*.rb"].each do |f|
	$log.debug "#{f} load"
	x=load(f)
	if x==false
		$log.fatal  "#{f} load error" 
	end
end

$param[:addon]||=['FreeMindAddon','TestCaseAddon']
$param[:code]||=[]
$opts=OptionParser.new do |opts|
	opts.banner = "
		gdbtest
		ruby gdbtest.rb -x 'gdb -q  a.exe' -s test.cpp:38 -e test.cpp:37
	"
	$param[:addon].each do |v|
		o=v.downcase.split('addon')[0]
		$gdbtest.config[:addon][o]=eval "#{v}.new"
		$gdbtest.config[:addon][o].parse opts,$param
	end

	opts.on("-d:", "--dir code", "directory for source code") do |v|
		$param[:dir] = v
	end
	opts.on("-x", "--gdb cmd", "command line for gdb running, such as gdb -q --args xxx -f xx.conf") do |v|
		$param[:gdb] = v
	end
	opts.on("-f", "--file file", "one file include sources list") do |v|
		$param[:files] = v
	end
	opts.on("-b", "--breaks file", "one file include breaks list") do |v|
		$param[:break] = v
	end
	opts.on("-j", "--jump function", "remove breakpoint in function") do |v|
		$param[:skip] = v
	end
	opts.on("-s", "--start function", "record breakpoint when function start") do |v|
		$param[:start] = v
	end

	opts.on("-p", "--path path file", "get object from path file") do |v|
		$param[:path] = v
	end
	opts.on("-t", "--codetree yaml file", "code tree") do |v|
		$param[:tree] = v
	end
	opts.on("-l", "--level level", "level of log, FATAL WARN DEBUG INFO") do |v|
		$param[:level] = v
	end


	opts.on("-e", "--encoding gbk", "set the encoding of gdb output") do |v|
		$param[:encoding] = v
	end
	opts.on("", "--code branch", "break on the branchs which analyse from code, you can set to line loop mem") do |v|
		$param[:code] << v
	end
	opts.on("", "--breakcmd cmd", "run gdb cmd in every breakpoint") do |v|
		$param[:breakcmd] = v
	end

	opts.on_head("-a", "--addon yourself.rb", "use your file to extend gdbtest") do |v|
		$param[:addon] ||=[]
		$param[:addon].unshift v
		o=v.downcase.split('addon')[0]
		$gdbtest.config[:addon][o]=eval "#{v}.new"
		$gdbtest.config[:addon][o].parse opts,$param
	end

end

$opts.parse(ARGV)
$gdbtest.config[:addon].each do |v|
	$addons.delete v if v.class.to_s=='TestCaseAddon' && $param[:key]==nil
end
$gdbtest.parse($param)
#end

