class ItemsController < ApplicationController
  # GET /items
  # GET /items.json
  
  require 'will_paginate/array'
  before_filter :query, :only => [:search]
  
  caches_action :show, :cache_path => proc { |i|  
	  item = Item.find i.params[:id]
	  {:tag => item.updated_at.to_i}
  }
  
  caches_action :index, :cache_path => proc {|i|
	  if !params[:page].blank?
		page = params[:page].to_i
	  else
		page = 1
	  end
	  item = Item.order('id ASC').limit(50).offset(page*50-50).sort_by{|i| i.updated_at}.last
	  {:tag => item.updated_at.to_i*1000 + page}
  }
  
  caches_action :search, :cache_path => proc {|i| {:tag => @cache.to_s} }
  
  def search
	respond_to do |format|
		format.html # index.html.erb
		format.json { 
			@build_json = {	:current_page => @items.current_page,
							:per_page => @items.per_page,
							:total_entries => @items.total_entries,
							:item => @items.collect{|item| 
							[item.id, :image => item.image.url, :thumb => item.image.url(:thumb), :preview => item.image.url(:preview), 
							:properties => item.properties.collect{|property| [property.name, property.values.where(:item_id => item.id)]}]}}
			render :json => @build_json.to_json(:only => [:current_page, :per_page, :total_entries, :item, :id, :image, :thumb, :preview, :properties, :name]) 
		}
	end
  end
  
  def index
    @items = Item.all.paginate(:per_page => 50, :page => params[:page])
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
    end
  end

  # GET /items/1
  # GET /items/1.json
  def show
    @item = Item.find(params[:id])
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
	@build_json = {:id => @item.id, :image => @item.image.url, :thumb => @item.image.url(:thumb), :preview => @item.image.url(:preview), :properties => @item.properties.collect{|property| [property.name, property.values.where(:item_id => @item.id)]}}
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @build_json }
    end
  end

  # GET /items/1/edit
  def edit
    @item = Item.find(params[:id])
  end

  # POST /items
  # POST /items.json
  def create
    @item = Item.new(params[:item])
	
    respond_to do |format|
      if @item.save
        format.html { redirect_to @item, notice: 'Item was successfully created.' }
        format.json { head :ok}
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
      format.html { redirect_to items_url }
      format.json { head :ok }
    end
  end
  
  protected
	def query
		## new key/value pair search
		@items = Item.joins(:values, :properties) # create an item pointer that points to everything in the DB

		if !params["pair"].blank? 
			params["pair"].each do |pair| 
				@items = @items.find(:all, :conditions => ["properties.id = ? AND values.name REGEXP ?", pair["property_id"], pair["value"]])
			end
		end
		
		if !params[:property_id].blank?
			@items = @items.find(:all, :conditions => ["properties.id IN ?", params[:property_id]])
		end
		
		if !params[:value].blank?
			params[:value].each do |value|
				@items = @items.find(:all, :conditions => ["values.name REGEXP ?", value["value"]])
			end
		end
		
		# get rid of the join table - messes up JSON output (for now)
		@items = Item.find(@items.collect{|item| [item.id]})
		
		if params["pair"].blank? && params[:value].blank? && params[:property_id].blank?
			@items = Item.all
		end
		@items = @items.paginate(:per_page => 50, :page => params[:page])
		@cache = Digest::MD5.hexdigest(@items.to_json())
	end
  
end