class Admin::KanjisController < ApplicationController
  before_action :set_kanji, only: %i[show edit update destroy]

  def index
    @kanjis = Kanji.all.order(created_at: :desc)
  end

  def show; end

  def new
    @kanji = Kanji.new
  end

  def edit; end

  def create
    @kanji = Kanji.new(kanji_params)
    if @kanji.save
      redirect_to admin_kanjis_path, notice: "Tạo Kanji thành công."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @kanji.update(kanji_params)
      redirect_to admin_kanjis_path, notice: "Cập nhật thành công."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @kanji = Kanji.find(params[:id])
    @kanji.destroy
    redirect_to admin_kanjis_path, notice: "Đã xóa Kanji thành công.", status: :see_other
  end

  private

  def set_kanji
    @kanji = Kanji.find(params[:id])
  end

  def kanji_params
    params.require(:kanji).permit(
      :character, :onyomi, :kunyomi, :jlpt_level,
      :kanji_story, :meaning, :translation,
      :stroke_count, :components, :radical,
      :examples, :example_sentences, :writing_image_url
    )
  end
end