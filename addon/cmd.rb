
class CmdAddon < GDBTestAddon
	def init
		require 'yaml'
		@file_cmd_sh="cmd.sh"
		@file_cmd_rb="cmd.rb"
	end
	def do_start

	end
	def do_break(node)
		p `sh #{@file_cmd_sh}` if File.exist? @file_cmd_sh
		eval(File.read(@file_cmd_rb)) if File.exist? @file_cmd_rb
		
	end
end
