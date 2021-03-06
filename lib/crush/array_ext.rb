# Crush mixes in Crush::Commands in order to allow operations on groups of
# Crush::Entry items.  For example, dir['**/*.rb'] returns an array of files, so
# dir['**/*.rb'].destroy would destroy all the files specified.
#
# One cool tidbit: the array can contain entries anywhere, so you can create
# collections of entries from different servers and then operate across them:
#
#   [ box1['/var/log/access.log'] + box2['/var/log/access.log'] ].search /#{url}/
class Array
	include Crush::Commands

	def entries
		self
	end

	include Crush::FindBy

	include Crush::HeadTail
end
