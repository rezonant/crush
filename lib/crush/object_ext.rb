
class Object
	def probe_interface(hash)
		args = hash[:args] or args = []
		hash.select { |k,v| k != :args }.each do |message,block|
			if (message.kind_of? Class and self.kind_of? message) or
					message.nil? or (not message.kind_of? Class and self.respond_to? message)
				return block.call(*args)
			end
		end
	end
end

#	obj.probe_interface(
#		:member? => lambda {