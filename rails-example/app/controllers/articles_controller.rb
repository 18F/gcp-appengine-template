class ArticlesController < ApplicationController
  def new
    if /ZAP\/2.7/ =~ request.user_agent
      logger.info "not allowing scanner to post"
      render plain: "403 scanner not allowed to add data", status: 403
    else
      logger.info request.inspect
      @article = Article.new
    end
  end

  def edit
    @article = Article.find(params[:id])
  end

  def destroy
    @article = Article.find(params[:id])
    @article.destroy

    logger.info request.inspect

    redirect_to articles_path
  end

  def index
    logger.info request.inspect

    @articles = Article.all
  end

  def update
    @article = Article.find(params[:id])
 
    if @article.update(article_params)
      redirect_to @article
    else
      render 'edit'
    end
  end

  def show
    logger.info request.inspect

    @article = Article.find(params[:id])
  end

  def create
    @article = Article.new(article_params)
    logger.info request.inspect
   
    if @article.save
      redirect_to @article
    else
      render 'new'
    end
  end
 
  private
    def article_params
      params.require(:article).permit(:title, :text)
    end
end

