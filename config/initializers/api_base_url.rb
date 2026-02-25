Rails.configuration.x.api_base_url = ENV.fetch("API_BASE_URL", "https://109b-14-191-33-21.ngrok-free.app").to_s.sub(%r{/*\z}, "")
