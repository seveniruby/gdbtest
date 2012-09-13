#测试用例类，用于测试用例管理
class TestCase
	attr_accessor :mark
	def initialize
		@session={}
		@mark='init'
	end
	def create(node)
		@session[node[:thread]]||={}
		@session[node[:thread]][:index]||=0
		@session[node[:thread]][:index]+=1
		@session[node[:thread]][:start]=true
		@session[node[:thread]][:end]=false
		@session[node[:thread]][:tcs]||={}
		index=@session[node[:thread]][:index]
		@session[node[:thread]][:tcs][index]||={}
		@session[node[:thread]][:tcs][index][:path]=[]
		@session[node[:thread]][:tcs][index][:data]=index
	end

	def path_add(node)
		if @session[node[:thread]][:end]==false && @session[node[:thread]][:start]=true
			index=@session[node[:thread]][:index]	
			@session[node[:thread]][:tcs][index][:path]<<node[:line]
		end
	end
	def path_set(node,path=[])
		index=@session[node[:thread]][:index]	
		@session[node[:thread]][:tcs][index][:path]=path
	end
	def data_set(node,data)
		if  @param[:key]!=nil && @session[node[:thread]][:start]==true
			index=@session[node[:thread]][:index]	
			@session[node[:thread]][:tcs][index][:data]=data
		end
	end
	def in?(node)
		@session[node[:thread]][:start]==true
	end

	def exist?
		@session!=nil
	end
	def thread_exit?(node)
		@session[node[:thread]]!=nil
	end

	def close(node)
		if @session[node[:thread]][:start]==true
			@session[node[:thread]][:start]=false
			@session[node[:thread]][:end]=true
		else
			return
		end
	end

	def get_session
		@session		
	end

	def get_index(node)
		@session[node[:thread]][:index]	
	end
	def get_tc(node)
		index=@session[node[:thread]][:index]	
		@session[node[:thread]][:tcs][index]
	end

	def tcs
		@path_data={}
		@session.each do |k,v|
			v[:tcs].each do |kk,vv|
				@path_data[vv[:path]]||=[]
				@path_data[vv[:path]]<<vv[:data]
			end
		end	
		@path_data.values
	end
	def tcs_uniq
		@path_data={}
		@session.each do |k,v|
			v[:tcs].each do |kk,vv|
				@path_data[vv[:path].uniq]||=[]
				@path_data[vv[:path].uniq]<<vv[:data]
			end
		end	
		@path_data.values
	end
end
