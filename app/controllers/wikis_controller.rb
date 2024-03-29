class WikisController < ApplicationController

  before_action :authorize_user, only: [:destroy, :edit, :update]
  impressionist actions: [:show]

  def index
    @wikis = Wiki.all
    if params[:search]
      @wikis = Wiki.search(params[:search]).order("created_at DESC")
    else
      @wikis = Wiki.all.order("created_at DESC")
    end
  end

  def most_popular
    @wikis = Wiki.all
  end

  def most_recent
   @wikis  = Wiki.all.order('created_at DESC')
  end

  def your_likes
    @wikis = current_user.votes
  end

  def followed_users
    @wikis = Wiki.followed_users(current_user.following).order('created_at DESC')
  end

  def all_wikis
    @wikis = Wiki.all
  end

  def show
     @wiki = Wiki.find(params[:id])
     authorize @wiki
     unless @wiki.public || current_user
      flash[:alert] = "You must be signed in to view private wikis."
      redirect_to root_path

     authorize @wiki
    end
  end

  def new
    @wiki = Wiki.new
    @categories = Category.all.map{|c| [c.name, c.id] }
  end

  def create
    @wiki = Wiki.new(wiki_params)
    @wiki.category_id = params[:category_id]
    @wiki.user = current_user
    @categories = Category.all.map{|c| [c.name, c.id] }

    if current_user.wikis.today.count <= 2 || current_user.premium?
      @wiki.save
      flash[:notice] = "Log was saved successfully."
      redirect_to @wiki
    elsif current_user.wikis.today.count > 2
      flash.now[:alert] = "Exceeded post limit for today. Upgrade to premium for unlimited sharing"
      render :new
    end
  end

  def edit
    @wiki = Wiki.find(params[:id])
    @categories = Category.all.map{|c| [c.name, c.id ] }

    respond_to do |format|
     format.html
     format.js
   end
  end

  def update
     @wiki = Wiki.find(params[:id])
     @wiki.category_id = params[:category_id]

     if @wiki.update_attributes(wiki_params)
       flash[:notice] = "Wiki was updated successfully."
       redirect_to @wiki
     else
       flash.now[:alert] = "There was an error saving the wiki. Please try again."
       render :edit
     end
   end

   def destroy
    @wiki = Wiki.find(params[:id])

    if @wiki.destroy
      flash[:notice] = "\"#{@wiki.title}\" was deleted successfully."
      redirect_to wikis_path
    else
      flash.now[:alert] = "There was an error deleting the log."
      render :show
    end
  end

  private

  def wiki_params
    params.require(:wiki).permit(:title, :body, :description, :image, :category_id, :public)
  end

  def authorize_user
    wiki = Wiki.find(params[:id])
  unless current_user == wiki.user || current_user.admin?
    flash[:alert] = "You do not have acesss to do that"
    redirect_to root_path
  end
 end

 def today
  where(:created_at => (Time.zone.now.beginning_of_day..Time.zone.now))
 end
end
