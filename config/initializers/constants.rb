SAMPLE_YAML = File.open("#{Rails.root}/lib/default_yaml.yml").to_a.join("")
CF_CREDENTIALS = YAML.load File.open("#{Rails.root}/config/cf_credentials.yml")

