class ItemsController < ApplicationController
  # GET /items
  # GET /items.json
  
  require 'will_paginate/array' # for pagination
  before_filter :get_index, :only => [:index] # runs index sorting/fancy stuff before caching
  before_filter :write_pagination_to_cookie, :only => [:index] # gets number of items in DB

  ##################### CACHES ######################
  
  # caching the show pages - easy
  caches_action :show, :cache_path => proc { |i|  
	  item = Item.find i.params[:id]
	  {:tag => item.updated_at.to_i}
  }
  
  # caching index - difficult
  # params to cache by
  # 	page
  # 	sort order
  # 	date/time offset
  # 	time an item was updated		
  
  caches_action :index, :cache_path => proc {|i|
	page = 1
	page = params[:page].to_i unless params[:page].blank? 
	if !params[:sort_by].blank? && !params[:order].blank?
		item = Item.find(@values.collect{|v| v.item_id}).sort_by{|i| i.updated_at}.last
	elsif !params[:order].blank?  # ordering but no sorting
		item = Item.order("id #{params[:order].to_s}").limit(50).offset(page*50-50).sort_by{|i| i.updated_at}.last
	elsif !params[:offset].blank?
		item = Item.where(:created_at => (params[:offset].to_datetime)..Time.now).order('id ASC').limit(50).offset(page*50-50).sort_by{|i| i.updated_at}.last
	else
		item = Item.order('id ASC').limit(50).offset(page*50-50).sort_by{|i| i.updated_at}.last
	end
	@time = 0
	@time = item.updated_at.to_s unless item.blank?
	@params = i.request.url.to_s
	@cache = "#{@time}#{@params}"
	{:tag => @cache}
  }
  
  # caching search 
  # just check the last updated item 
  caches_action :search, :cache_path => proc {|i| 
	@time = Item.order('updated_at DESC').limit(1).find(:all).first.updated_at.to_s 
	@params = i.params.to_s
	@cache = "#{@time}#{@params}"
	{:tag => @cache}
  }
  
  cache_sweeper :item_sweeper, :only => [:create, :update, :destroy]
  
  ########### functions #############
  
  def search
	@joined = false
	@items = nil
	
	if !params["pair"].blank? 
		if !@joined
			@joined = true
		end
		params["pair"].each do |hash,pair| 
			if pair["property_name"].blank?
				@property = Property.find(pair["property_id"])
				@valuename = pair["value"]
				@values = Value.includes(:item).joins(:property).find(:all, :conditions => ["values.name LIKE ? AND properties.name LIKE ?", @valuename, @property.name])
				if !@items.nil?
					@items = @values.collect{|value| value.item} & @items
				else
					@items = @values.collect{|value| value.item}
				end
			else
				@valuename = pair["value"]
				@propertyname = pair["property_name"]
				@values = Value.includes(:item).joins(:property).find(:all, :conditions => ["values.name LIKE ? AND properties.name LIKE ?", @valuename, @propertyname])
				if !@items.nil?
					@items = @values.collect{|value| value.item} & @items
				else
					@items = @values.collect{|value| value.item}
				end
			end
		end
	end
			
	if !params[:property_id].blank?
		if !@joined
			@joined = true
		end
		if !@items.nil?
			@items = Item.includes(:properties).find(:all, :conditions => ["properties.id IN (?)", params[:property_id]]) & @items
		else
			@items = Item.includes(:properties).find(:all, :conditions => ["properties.id IN (?)", params[:property_id]])
		end
	end
			
	if !params[:value].blank?
		if !@joined
			@joined = true
		end
		@value = params[:value]
		@value.each {|hash,x| @query = x}
		@values = Value.search(@query)
		if !@items.nil?
			@items = Item.includes(:properties).find(@values.collect {|value| [value.item_id]}) & @items
		else
			@items = Item.includes(:properties).find(@values.collect {|value| [value.item_id]})
		end
	end
	
	# get us out of here if we don't need to be here
	if @items.blank? && !@joined
		redirect_to :action => "index", :format => params[:format]
		return
	end
	
	# get rid of the join table - messes up JSON output (for now)
	if @joined
		# do nothing
	end		
	
	if params[:sort_by].blank? && params[:order].blank? # no sorting or ordering
		# do nothing
	elsif !params[:order].blank? && params[:sort_by].blank? # ordering but no sorting
		if params[:order].to_s == 'DESC'
			@items = @items.sort_by{|i| -i.id}
		else
			@items = @items.sort_by{|i| i.id}
		end
	else # run the complex sorting
		@properties = Property.where(:name => params[:sort_by])
		@values = Value.order("name #{params[:order].to_s}").find(:all, :conditions => ["property_id IN (?) AND item_id IN (?)", @properties.collect{|p| p.id.to_i}, @items.collect{|item| item.id}], :include => [:item])
		@items = []
		@values.each do |v|
			@item = v.item
			@items << @item
		end
	end		
	@items = @items.paginate(:per_page => 50, :page => params[:page])
	respond_to do |format|
		format.html # search.html.erb (doesn't exist)
		format.json { 
			@build_json = {	:current_page => @items.current_page,
							:per_page => @items.per_page,
							:item => @items.collect{|item| 
							[item.id, :image => item.image.url, :thumb => item.image.url(:thumb), :preview => item.image.url(:preview), 
							:properties => item.properties.collect{|property| [property.name, property.values.where(:item_id => item.id)]}]}}
			render :json => @build_json.to_json(:only => [:current_page, :per_page, :item, :id, :image, :thumb, :preview, :properties, :name]) 
		}
	end
  end
  
  def index
	if !params[:sort_by].blank? && !params[:order].blank?
		@items = []
		@values.each do |v|
			@item = v.item
			@items << @item
		end
		@items = @items.uniq.paginate(:per_page => 50, :page => params[:page])
	elsif !params[:order].blank?  # ordering but no sorting
		@items = Item.includes(:properties).order("id #{params[:order].to_s}").paginate(:per_page => 50, :page => params[:page])
	end
	if !params[:offset].blank? # provide a time offset
		if !@items.blank?
			@items = Item.includes(:properties).where(:created_at => (params[:offset].to_datetime)..Time.now) & @items
		else
			@items = Item.includes(:properties).where(:created_at => (params[:offset].to_datetime)..Time.now)
		end
		@items = @items.paginate(:per_page => 50, :page => params[:page])
	elsif params[:sort_by].blank? && params[:order].blank? # no sorting or ordering
		@items = Item.includes(:properties).paginate(:per_page => 50, :page => params[:page])
	end
    respond_to do |format|
      format.html # index.html.erb
      format.json { 
		@build_json = {	:current_page => @items.current_page,
						:per_page => @items.per_page,
						:item => @items.collect{|item| 
						[item.id, :image => item.image.url, :thumb => item.image.url(:thumb), :preview => item.image.url(:preview), 
						:properties => item.properties.collect{|property| [property.name, property.values.where(:item_id => item.id)]}]}}
		render :json => @build_json.to_json(:only => [:current_page, :per_page, :item, :id, :image, :thumb, :preview, :properties, :name]) 
	  }
	  format.xml { @build_json = {	:current_page => @items.current_page,
						:per_page => @items.per_page,
						:item => @items.collect{|item| 
						[item.id, :image => item.image.url, :thumb => item.image.url(:thumb), :preview => item.image.url(:preview), 
						:properties => item.properties.collect{|property| [property.name, property.values.where(:item_id => item.id)]}]}}
		render :xml => @build_json.to_xml(:only => [:current_page, :per_page, :item, :id, :image, :thumb, :preview, :properties, :name])
	  }
    end
  end

  # GET /items/1
  # GET /items/1.json
  def show
    @item = Item.includes(:properties).find(params[:id])
	@build_json = {:id => @item.id, :image => @item.image.url, :thumb => @item.image.url(:thumb), :preview => @item.image.url(:preview), :properties => @item.properties.collect{|property| [property.name, property.values.where(:item_id => @item.id)]}}
    respond_to do |format|
      format.html # show.html.erb
	  format.xml  { render xml: @build_json}
      format.json { render :json => @build_json.to_json(:only => [:id, :image, :thumb, :preview, :properties, :name]) }
    end
  end

  # GET /items/new
  # GET /items/new.json
  def new
    @item = Item.new
	1.times do
		@item.values.build.build_property
	end
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @item }
    end
  end

  # GET /items/1/edit
  def edit
    @item = Item.find(params[:id])
	1.times do
		@item.values.build.build_property
	end
  end

  # POST /items
  # POST /items.json
  def create
    @item = Item.new(params[:item])
    respond_to do |format|
      if @item.save
        format.html { redirect_to @item, notice: 'Item was successfully created.' }
        format.json { head :ok }
      else
        format.html { render action: "new" }
        format.json { render json: @item.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /items/1
  # PUT /items/1.json
  def update
    @item = Item.find(params[:id])
    respond_to do |format|
      if @item.update_attributes(params[:item])
        format.html { redirect_to @item, notice: 'Item was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @item.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /items/1
  # DELETE /items/1.json
  def destroy
    @item = Item.find(params[:id])
    @item.destroy

    respond_to do |format|
      format.html { redirect_to(:back) }
      format.json { head :ok }
    end
  end
  
  ################# filters ####################
  
  protected
	def write_pagination_to_cookie # runs before index is called
		if !params[:sort_by].blank? && !params[:order].blank?
			@total_entries = @values.count
		elsif !params[:offset].blank?
			@total_entries = Item.where(:created_at => (params[:offset].to_datetime)..Time.now).count
		else
			@total_entries = Item.count
		end
		@total_pages = @total_entries / 50.0			
		cookies['total_entries'] = @total_entries.to_json
		cookies['total_pages'] = @total_pages.ceil.to_json
	end
	
	def get_index # runs before index and the cache is called
		if !params[:sort_by].blank? && !params[:order].blank? # sorting and ordering
			@properties = Property.where(:name => params[:sort_by])
			@values = Value.order("name #{params[:order].to_s}").find(:all, :conditions => ["property_id IN (?)", @properties.collect{|p| p.id}], :include => [:item])
		end
	end

end