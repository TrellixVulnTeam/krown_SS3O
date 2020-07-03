class Attachment < ApplicationRecord
  belongs_to :knowledge
  mount_uploader :image, ImageUploader

  validate :file_type_check

  def public_path
    @public_path ||= "public".freeze
  end

  #ファイルサイズを取得する
  def get_file_size
    if self.image.url
      stat = File.stat(File.join(public_path,self.image.url))
      stat.size
    end

  end

  #ファイル名を取得する
  def get_name
      File.basename(File.join(public_path,self.image.url)) if self.image.url
  end

  #イメージファイルの大きさを取得する
  def get_image_size
    image_size = FastImage.size(File.join(public_path,self.image.url)) if self.image.url
  end

  #イメージファイルのタイプを取得する
  def get_type
    image_size = FastImage.type(File.join(public_path,self.image.url)) if self.image.url
  end

  #添付されたファイルが以下の種類以外は保存できない。
  # 許容ファイル属性：png,jpg,gif
  def file_type_check
    if file_type.in?(['png','jpg','gif'])
      true
    else
      errors.add(:file_type , "指定のファイル属性を添付してください。")
      false
    end

  end


end