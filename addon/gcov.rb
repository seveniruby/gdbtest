#coding: utf-8
require 'gdb'
require 'pathname'
require 'pp'

#use gcov to build your program   -ftest-coverage -fprofile-arcs .  don't use -coverage 
#完全可以更快，目前只是为了方便沟通和理解
class GcovAddon < GDBTestAddon
	def init
		@tcs=[] 
		@paths=[]
		$gdb_verbose=false
		@dir=@param[:dir]
		@dir||='.'
		@index=1
		@started={}
		@start_index={}
		@info_file='gdbtest/tc'
	end
	def parse(opts,param)
		opts.on("", "--branch", "break on the branch") do |v|
			param[:branch] = v
		end
	end
	def do_start
		@gdbtest.g.run 'call __gcov_flush()'
		file='app.info.start'
		#`env lcov -z -d #{@dir}`
		p "env lcov -c -d #{@dir} -o #{file}"
		`env lcov -c -d #{@dir} -o #{file}`
		@new=appinfo(file)
		@base=@new.clone
		if @param[:branch]
			@new.values.select{|x| x[:type]=='BRDA'}.map{|x| x[:file]+":"+x[:line]}.uniq.each do |line|
				@gdbtest.breaks<<line
			end
		end
	end
	def do_stop(node)
		gcov_dump(node)
	end

	def gcov_dump(node)
		return if node[:function]!=@param[:key]
		gcov_end
		gcov_start
		@index+=1
	end

	def tc_start
		@gdbtest.g.run "call __gcov_flush()"
		p "env lcov -z -d #{@dir}"
		`env lcov -z -d #{@dir}`
	end
	def tc_end
		file_gcov="#{@info_file}.#{@index}.info"
		@gdbtest.g.run "call __gcov_flush()"
		p "env lcov -d #{@dir} -c -o #{file_gcov}"
		`env lcov -d #{@dir} -c -o #{file_gcov}`
		@old=@new.clone
		@new=appinfo(file_gcov)
		info_change(@new)
		@index+=1
	end
	def tc_path_get
		@tc_path
	end


	def report
		@gdbtest.dump @paths,"gdbtest.paths"
		datas={}
		i=0
		@paths.each do |path|	
			datas[path]||=[]
			datas[path]<<i
			i+=1
		end
		@gdbtest.dump datas,"gdbtest.data"

	end
	def appinfo(file)
		appinfo={}
		IO.read(file).split("\nend_of_record\n").each do |r|
			record={}
			file=''
			line=0
			node={}
			skip=false
			r.each_line do |line|
				break if skip
				line.strip!
				case line.split(':')[0]
				when 'BRDA'
					brda=line.split(/:|,/)
					appinfo["#{file}:#{brda[1]}:#{brda[-2]}"]={ :file=>file,:line=>brda[1],:type=>brda[0],:branch=>brda[-2],:coverage=>brda[-1]=='-'|| brda[-1]=='0'}
				when 'SF'
					path=Pathname.new line.split('SF:')[1]
					if !path.file? || path.dirname.realpath.to_s.index(Pathname.new(@dir).realpath.to_s)!=0
						skip=true
						break
					end
					file=path.basename.to_s
				when "DA"
					da=line.split(/:|,/)
					appinfo["#{file}:#{da[1]}"]={:file=>file,:line=>da[1],:type=>da[0],:branch=>"0",:coverage=>da[-1]!='0'}
				end
			end
		end
		return appinfo

	end
	def info_change(new)
		#return if !old || old==[]
		path=[]
		new.keys.each do |k|
			#if old[k][:coverage]!=new[k][:coverage]
			if new[k][:coverage]==true
				#path<<k.split(':')[0..1].join(':')
				path<<k
			end
		end
		@gdbtest.dump path,"gdbtest/tc.#{@index}.path"
		path.uniq!
		@gdbtest.dump path,"gdbtest/tc.#{@index}.path.uniq"
		@paths<<path
		#@gdbtest.tc.path_set @node,path
		@tc_path=path
	end
end
