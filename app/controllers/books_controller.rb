class BooksController < ApplicationController
  before_action :set_book, only: [:show, :edit, :update, :destroy]

  def index
    @books = if params[:search]
      Book.where('title LIKE ? OR author LIKE ?', "%#{params[:search]}%", "%#{params[:search]}%")
    else
      Book.all
    end
  end

  def show
  end

  def new
    @book = Book.new
  end

  def create
    @book = Book.new(book_params)
    if @book.save
      redirect_to @book, notice: '本が正常に追加されました。'
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @book.update(book_params)
      redirect_to @book, notice: '本の情報が正常に更新されました。'
    else
      render :edit
    end
  end

  def destroy
    @book.destroy
    redirect_to books_url, notice: '本が正常に削除されました。'
  end

  private

  def set_book
    @book = Book.find(params[:id])
  end

  def book_params
    params.require(:book).permit(:title, :author, :isbn, :description)
  end
end
