require "active_support/core_ext/integer/time"

Rails.application.configure do
  # 1. Cấu hình Mailer cơ bản
  config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true # Bật lỗi để debug nếu gửi mail thất bại
  config.action_mailer.perform_caching = false

  # 2. Cấu hình gửi Mail qua Gmail (Sử dụng mật khẩu ứng dụng bạn đã tạo)
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    address:              'smtp.gmail.com',
    port:                 587,
    domain:               'gmail.com',
    user_name:            'KanjiTogether.official@gmail.com',
    password:             'tjghwmgtexdpkhks',
    authentication:       'plain',
    enable_starttls_auto: true
  }

  # --- GIỮ NGUYÊN CÁC THIẾT LẬP CŨ CỦA BẠN DƯỚI ĐÂY ---

  config.enable_reloading = true
  config.eager_load = false
  config.consider_all_requests_local = true
  config.server_timing = true
  config.action_mailer.default_options = { from: 'KanjiTogether Support <KanjiTogether.official@gmail.com>' }
  if Rails.root.join("tmp/caching-dev.txt").exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true
    config.public_file_server.headers = { "cache-control" => "public, max-age=#{2.days.to_i}" }
  else
    config.action_controller.perform_caching = false
  end

  config.cache_store = :memory_store
  config.active_storage.service = :local
  config.active_support.deprecation = :log
  config.active_record.migration_error = :page_load
  config.active_record.verbose_query_logs = true
  config.query_log_tags_enabled = true
  config.active_job.verbose_enqueue_logs = true
  config.action_dispatch.verbose_redirect_logs = true
  config.assets.quiet = true
  config.action_view.annotate_rendered_view_with_filenames = true
  config.action_controller.raise_on_missing_callback_actions = true
end