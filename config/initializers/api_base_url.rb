Rails.configuration.x.api_base_url = ENV.fetch("API_BASE_URL", "https://6c85d19fdc72.ngrok-free.app").to_s.sub(%r{/*\z}, "")
