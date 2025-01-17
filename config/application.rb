require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Krown
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    #簡易読み込みさせるため、試してみたが失敗。メモしておく。
    #config.enable_dependency_loading = true
    #config.autoload_paths += %W(#{Rails.root}/app/services)
    #config.autoload_paths += Dir["#{config.root}/services/**/"]

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.


    # 更新失敗時に表示される更新フォームのクラスを無効化する
    config.action_view.field_error_proc = Proc.new { |html_tag, instance| html_tag }
  end
end
