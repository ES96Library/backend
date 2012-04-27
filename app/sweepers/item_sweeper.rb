class ItemSweeper < ActionController::Caching::Sweeper
	observe Item

	def after_save(item)
		clear_items_cache(item)
	end
	
	def after_destroy(item)
		clear_items_cache(item)
	end
	
	def clear_items_cache(item)
		expire_page :controller => :items, 
					:action => :show, 
					:id => item
	end	
end