
class UnitAddon < GDBTestAddon
	def init
		@unit_data={}
		@file_unit="unit.data"

	end
	def do_start

	end
	def do_break(node)
		function=@gdbtest.g.run('bt 1').join.split[1]
		args=@gdbtest.g.run('info args')
		return if !args.join.index("=")
		code=""
		args.each do |a|
			name=a.split[0]
			p val2code(name)
			code+=val2code(name)
			code+="\n"
		end
		@unit_data[function]||=[]
		@unit_data[function]<<code if !@unit_data[function].index(code)
		@gdbtest.dump @unit_data,@file_unit
	end
	def val2code(name)
		p name
		info=@gdbtest.g.run("ptype #{name}")
		value=@gdbtest.g.run("p #{name}")[0].split[-1]
		if info[0].split[2]=="int"
			code="int #{name}=#{value}" 
		end
		if info[0].split[2]=="char"
			code="char #{info[0].split[3]} #{name}=#{value}" 
		end

		if info[0].split[2]=="struct" || info[0].split[2]=="class"
			if info[0].split[3].index('std::basic_string')
				value=@gdbtest.g.run("call printf(\"%s\",#{name})").join.split(' = ')[-1].strip
				code="string #{name}=\"#{value}\""
			else

				info[1..-2].each do |line|
					sub_name=line.split[-1].split(';')[0].split('*')[-1]
					code=val2code("#{name}->#{sub_name}")
				end
			end

		end
		code

	end
end
