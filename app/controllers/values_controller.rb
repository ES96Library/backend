class ValuesController < ApplicationController
  # GET /values
  # GET /values.json
  
  before_filter :query, :only => [:filters]
  
  def filters
	@values = []
	@properties.each do |v|
		@valuesub = []
		@propname = ''
		@propid = 0
		v.each do |i|
			if i.class != String
				i.each do |j|
					j.values.each do |k|
						@valuesub << k unless k.blank?
					end
					@propid = j.id
				end
			else
				@propname = i
			end
		end
		@values << {:id => @propid, :name => @propname, :values => @valuesub} unless @valuesub.blank?
	end
	respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @values.to_json(:except => [:created_at, :updated_at, :item_id, :property_id]) }
    end
  end
  
  def index
    @values = Value.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @values }
    end
  end

  # GET /values/1
  # GET /values/1.json
  def show
    @value = Value.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @value }
    end
  end

  # GET /values/new
  # GET /values/new.json
  def new
    @value = Value.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @value }
    end
  end

  # GET /values/1/edit
  def edit
    @value = Value.find(params[:id])
  end

  # POST /values
  # POST /values.json
  def create
    @value = Value.new(params[:value])

    respond_to do |format|
      if @value.save
        format.html { redirect_to @value, notice: 'Value was successfully created.' }
        format.json { render json: @value, status: :created, location: @value }
      else
        format.html { render action: "new" }
        format.json { render json: @value.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /values/1
  # PUT /values/1.json
  def update
    @value = Value.find(params[:id])

    respond_to do |format|
      if @value.update_attributes(params[:value])
        format.html { redirect_to @value, notice: 'Value was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @value.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /values/1
  # DELETE /values/1.json
  def destroy
    @value = Value.find(params[:id])
    @value.destroy

    respond_to do |format|
      format.html { redirect_to :back }
      format.json { head :ok }
    end
  end
  
  protected
	def query
		## new key/value pair search
		@joined = false
		
		if !params["pair"].blank? 
			if !@joined
				@items = Item.joins(:values, :properties) # create an item pointer that points to everything in the DB
				@joined = true
			end
			params["pair"].each do |hash,pair| 
				if pair["property_name"].blank?
					@property = Property.find(pair["property_id"])
					@items = Item.joins(:values, :properties).find(:all, :conditions => ["properties.name LIKE ? AND values.name LIKE ?", @property.name, pair["value"]]) & @items
				else
					@items = Item.joins(:values, :properties).find(:all, :conditions => ["properties.name LIKE ? AND values.name LIKE ?", pair["property_name"], pair["value"]]) & @items
				end
			end
		end
		
		if !params[:property_id].blank?
			if !@joined
				@items = Item.joins(:values, :properties) # create an item pointer that points to everything in the DB
				@joined = true
			end
			@items = Item.find(:all, :conditions => ["properties.id IN (?)", params[:property_id]]) & @items
		end
		
		if !params[:value].blank?
			if !@joined
				@items = Item.joins(:values, :properties) # create an item pointer that points to everything in the DB
				@joined = true
			end
			@value = params[:value]
			@value.each {|hash,x| @query = x}
			@values = Value.search(@query)
			@items = Item.find(@values.collect {|value| [value.item_id]}) & @items
		end
		
		# return relevant properties
		if @joined
			@items = Item.find(@items.collect{|item| [item.id]})
			@properties = @items.collect{|item| item.properties}.group_by(&:name)
		else
			@properties = Property.find(:all).group_by(&:name)
		end
	end
  
end
