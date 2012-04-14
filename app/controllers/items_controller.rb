class ItemsController < ApplicationController
  # GET /items
  # GET /items.json
  
  require 'will_paginate/array'
  
  def search
	## new key/value pair search
	@items = Item.joins(:values, :properties) # create an item pointer that points to everything in the DB
	if !params["pair"].blank?
		params["pair"].each do |pair| 
			@items = @items.where(:properties => {:id => pair["property_id"]}, :values => {:name => pair["value"]})
		end
		# get rid of the join table - messes up JSON output (for now)
		@items = Item.find(@items.collect{|item| [item.id]})
	else
		@search = 	Value.search do
					keywords params[:value]
					order_by(:score, :desc)
					paginate :page => params[:page], :per_page => 50
					with(:property_id, params[:property_id]) unless params[:property_id].blank?
					facet :property_id
				end.results
		@items = Item.find(@search.collect{|value| value.item_id})
	end
	@build_json = {:item => @items.collect{|item| [item.id, :image => item.image.url, :thumb => item.image.url(:thumb), :preview => item.image.url(:preview), :properties => item.properties.collect{|property| [property.name, property.values.where(:item_id => item.id)]}]}}
	respond_to do |format|
		format.html # index.html.erb
		format.json { render :json => @build_json.to_json(:only => [:item, :id, :image, :thumb, :preview, :properties, :name]) }
	end
  end
  
  def index
    @items = Item.all.paginate(:per_page => 50, :page => params[:page])
	@build_json = {:item => @items.collect{|item| [item.id, :image => item.image.url, :thumb => item.image.url(:thumb), :preview => item.image.url(:preview), :properties => item.properties.collect{|property| [property.name, property.values.where(:item_id => item.id)]}]}}
    respond_to do |format|
      format.html # index.html.erb
	  format.xml { render xml: @build_json}
      format.json { render :json => @build_json.to_json(:only => [:item, :id, :image, :thumb, :preview, :properties, :name]) }
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
	    @item = {:id => @item.id, :properties => @item.properties.collect{|property| [property.name, property.values.where(:item_id => @item.id)]}}
        format.html { redirect_to @item, notice: 'Item was successfully created.' }
        format.json { render json: @item, status: :created, location: @item }
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
	    @item = {:id => @item.id, :properties => @item.properties.collect{|property| [property.name, property.values.where(:item_id => @item.id)]}}
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
end
