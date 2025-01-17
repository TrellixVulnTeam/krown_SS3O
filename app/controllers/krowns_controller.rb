class KrownsController < ApplicationController
  include ApplicationHelper
  include KrownsHelper
  require 'fastimage'
  #protect_from_forgery except: :show

  #ユーザが所有しているグループの抽出
  before_action :select_genre
  #カウンター
  before_action :get_count
  #カラーグループ
  before_action :color_group_select

  def index
    # アプリケーション起動時、ログオンユーザがない場合は新規作成する
    #make_default_user if User.count == 0 && Genre.count == 0

    @knowledges = search_knowledge_data(page: params[:page])
    # 最新ナレッジが存在するかどうか
    set_sql = @knowledges.limit(1)
    @knowledge = set_sql[0]
    #インシデントに画像の添付ファイルがある場合は同様に取得する
    set_attachment(@knowledge)
  end

  def edit
    @knowledge = Knowledge.find(params[:id])
    @color_manage = @knowledge.color_manage_id ? ColorManage.find(@knowledge.color_manage_id) : nil

    render :template => 'krowns/new'
  end

  def show
    @knowledge = Knowledge.find(get_knowledge)

    set_attachment(@knowledge)
    @destroy_flg = true

    respond_to do | format|
      format.js
      #p request.format
    end
    # エラーになってしまうよ。render 'krowns/show.js.erb'

  end

  def new
    # 同時並行性は今回考慮しない(工数考慮)
    @knowledge = Knowledge.new(id: set_id(@knowledge))
  end

  def update
    begin
      @knowledge = Knowledge.find(params[:knowledge][:id])

      if @knowledge.id
        knowledge_service = UpdateKnowledgeService.new()
        knowledge_service.update_knowledge(params:params_knowledge)
      end

      # ナレッジに紐つくカラーがあり、且つカラーの更新がある場合
      if Knowledge.find(params[:knowledge][:id]).color_manage && params_color_mange[:color_flg] == "1"
        color_manage_service = UpdateColorManageService.new()
        color_manage_service.update_color_manage(params: params_color_mange)

      #ナレッジに紐つくカラーが無く、更新操作によってカラーが登録された場合
      elsif Knowledge.find(params[:knowledge][:id]).color_manage.nil? && params_color_mange[:color_flg] == "1"
        create_color_manage_service = CreateColorManageService.new()
        @color_manage = create_color_manage_service.color_manage_data_create(params_color_mange)

        @color_manage.save!
        @knowledge.update_attributes(color_manage_id: @color_manage.id)
      end

      redirect_to root_path, notice: 'ナレッジを作成しました'

    rescue
      render :new, notice: '更新内容を正しく入力してください'
    end

  end

  def create
    # ナレッジを作成するためのサービスを呼び出す
    create_knowledge_service = CreateKnowledgeService.new()
    @knowledge = create_knowledge_service.knowledge_data_create(params_knowledge)

    # 添付ファイルが存在した場合は、添付レコードを生成する
    if params_knowledge[:image]
      create_attachment_service = CreateAttachmentService.new()
      @attachment = create_attachment_service.attachment_data_create(@knowledge.image)
    end

    # カラーグループ設定が存在した場合は、レコードを生成する
    if params_color_mange[:color_flg] == "1"
      create_color_manage_service = CreateColorManageService.new()
      @color_manage = create_color_manage_service.color_manage_data_create(params_color_mange)
    end

    if knowledge_save
      redirect_to root_path notice: 'ナレッジを作成しました'
    else
      render :new
    end
  end

  def destroy
    krown = Knowledge.find(params[:id])
    # (仮)誰でも削除できるようにしておく
    # if krown.user_id == current_user.id || krown.user_id == 1
      krown.destroy
      redirect_to root_path, notice: 'ナレッジを削除しました'
    #end
  end

  def search
     @knowledges = Knowledge.where(genre_id: params[:format]).page(params[:page]).per(10).order("created_at DESC")
     wk_knowledge = Knowledge.where(genre_id: params[:format]).order("created_at DESC").limit(1)
     @knowledge = wk_knowledge[0]
     # テンプレートの流用(index)
     render :template => 'krowns/index'
  end

  def wordsearch
    @knowledges = search_result_knowledge_data(keywords: params[:keywords], page: params[:page])
    wk_knowledge = @knowledges.order("created_at DESC").limit(1)
    @knowledge = wk_knowledge[0]
  end

  def portfolio

  end


private

  # 詳細ぺージ出力用、検索用メソッド
  def get_knowledge
    params.require(:id)
  end

  # 編集ページ用、パラメータ取得用メソッド
  def params_knowledge
    params.require(:knowledge).permit(
      :id,
      :user_id,
      :genre_id,
      :title,
      :content,
      :keyword_1,
      :keyword_2,
      :yobi_1,
      :image,
      :created_at,
      :updated_at,
      :color_manage_id,
      :remark
      )
  end

  def params_color_mange
    hash_attributes = params.require(:knowledge).require(:color_manage_attributes)
    hash_attributes.permit(
        :id,
        :color_flg,
        :color_type,
        :color_1,
        :color_2,
        :group_word,
        :word_color,
        :group_flg
      )

  end

  def select_genre
    if user_signed_in?
      @genres = Genre.where(user_id: current_user.id.to_s)
    end
  end

  def set_id(knowledge)
    id = Knowledge.count != 0 ? Knowledge.maximum(:id) + 1 : 1
    id
  end

  def get_count
    if user_signed_in?
      @knowledge_count = Knowledge.where(user_id: current_user.id.to_s).count
      @genre_count = Genre.where(user_id: current_user.id.to_s).count
    else
      @knowledge_count = Knowledge.where(user_id: 1).count
      @genre_count = 0
    end
  end

 def make_default_user
   if User.count == 0
     MakeDefaultDataService.new(mode: 'new_data')
   end
 end

  def set_attachment(knowledge)
    if @knowledge.img_flg.to_i == 1
      @attachment = @knowledge.attachments[0]
    end
  end

  def color_group_select
    @color_select = ColorManage.where(group_flg: "1")
  end

end
