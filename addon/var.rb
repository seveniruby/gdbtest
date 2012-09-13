
class VarAddon < GDBTestAddon
	def init
	end
	def do_break(node)
		return if !node[:code].index("if")
		#p @gdbtest.g.run 'info locals'
		
		node[:code].split('if')[1..-1].join.scan(/[0-9a-zA-Z\._]{1,}/).each do |var|
			msg=@gdbtest.g.run "p #{var}"
			p var,msg
		end
	end
end
