class Line

  attr_accessor :errors, :cf_client, :yaml, :api_key, :custom_form_html_hash

  def initialize(params={})
    params ||= {}
    @errors = []
    if (line_yaml = params[:line_yaml]).present?
      @yaml = line_yaml
      @api_key = YAML.load(line_yaml)["api_key"]
      @custom_form_html_hash = ActiveSupport::HashWithIndifferentAccess.new(params[:html])
      initialize_cf_client(params[:cf_environment] || "default")
      @errors += @cf_client.errors
    end
  end

  def valid_yaml?
    @errors = []
    line_options_hash = ActiveSupport::HashWithIndifferentAccess.new({:line_yaml => @yaml}.merge(@custom_form_html_hash))
    @errors = @cf_client.validate(line_options_hash, source_is_a_path = false)
    @errors.empty?
  end

  def create_in_cf
    @errors = []
    line_dump = YAML::load(self.yaml)
    line = @cf_client.create_line(line_dump)
    @errors = line.errors if line.errors.present?
    @errors.empty?
  end

  # set the parameters to connect to cloudfactory
  def initialize_cf_client(cf_environment)
    @cf_client = CfClient.new(self.api_key, cf_environment)
  end

end

