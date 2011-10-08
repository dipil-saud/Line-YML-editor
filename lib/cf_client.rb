class CfClient
  require 'cf'
  require 'cf/cli'
  include Cf::LineYamlValidator

  @@lock = Mutex.new # for synchronization

  # These methods connect to cloudfactory, thus use the Cf credentials line CF.api_key, and CF.account_name
  # The credentials are global so the methods should be synchronized
  MethodsRequiringCFConnection = [
    "set_account_name",
    "find_line",
    "initialize_line"
  ]


  attr_accessor :api_key, :api_url, :api_version, :account_name, :errors

  def initialize(api_key, cf_environment)
    @errors = []
    cf_credentials = CF_CREDENTIALS[cf_environment]
    @api_version = cf_credentials["api_version"]
    @api_url = cf_credentials["api_url"]
    @api_key = api_key
    set_account_name
  end

  def set_account_name
    set_cf_credentials
    info = CF::Account.info
    info["error"].present? ? errors << info["error"]["message"] : @account_name = info["name"]
    clear_cf_credentials
  end

  # set the settings to connect to cloudfactory
  def set_cf_credentials
    CF.api_url = self.api_url
    CF.api_version = self.api_version
    CF.api_key = self.api_key
    CF.account_name = self.account_name
  end

  def clear_cf_credentials
    CF.api_url = nil
    CF.api_version = nil
    CF.api_key = nil
    CF.account_name = nil
  end

  def find_line(title)
    set_cf_credentials
      response = CF::Line.find(title)
    clear_cf_credentials
  end

  def create_line(line_dump)
    set_cf_credentials
    line = create_line_in_cf(line_dump)
    clear_cf_credentials
    return line
  end

  # Copy pasted and edited code from gem
  def create_line_in_cf(line_dump)
    line_title = line_dump['title'].parameterize
    line_description = line_dump['description']
    line_department = line_dump['department']
    line_public = line_dump['public']
    line = CF::Line.new(line_title, line_department, {:description => line_description, :public => line_public})
    return line if line.errors.present?

        # Creation of InputFormat from yaml file
        input_formats = line_dump['input_formats']
        input_formats.each_with_index do |input_format, index|
          if input_format['valid_type']
            @attrs = {
              :name => input_format['name'],
              :required => input_format['required'],
              :valid_type => input_format['valid_type']
            }
          elsif input_format['valid_type'].nil?
            @attrs = {
              :name => input_format['name'],
              :required => input_format['required'],
              :valid_type => input_format['valid_type']
            }
          end
          input_format_for_line = CF::InputFormat.new(@attrs)
          input_format = line.input_formats input_format_for_line
          line.errors = input_formats[index].errors and return line if line.input_formats[index].errors.present?
        end

        # Creation of Station
        stations = line_dump['stations']
        stations.each_with_index do |station_file, s_index|
          type = station_file['station']['station_type']
          index = station_file['station']['station_index']
          input_formats_for_station = station_file['station']['input_formats']
          batch_size = station_file['station']['batch_size']
          if type == "tournament"
            jury_worker = station_file['station']['jury_worker']
            auto_judge = station_file['station']['auto_judge']
            acceptance_ratio = station_file['station']['acceptance_ratio']
            station_params = {:line => line, :type => type, :jury_worker => jury_worker, :auto_judge => auto_judge, :input_formats => input_formats_for_station, :batch_size => batch_size, :acceptance_ratio => acceptance_ratio}
          else
            station_params = {:line => line, :type => type, :input_formats => input_formats_for_station, :batch_size => batch_size}
          end
          station = CF::Station.create(station_params) do |s|
            line.errors = s.errors and return line if s.errors.present?
            # For Worker
            worker = station_file['station']['worker']
            number = worker['num_workers']
            reward = worker['reward']
            worker_type = worker['worker_type']
            if worker_type == "human"
              skill_badges = worker['skill_badges']
              stat_badge = worker['stat_badge']
              if stat_badge.nil?
                human_worker = CF::HumanWorker.new({:station => s, :number => number, :reward => reward})
              else
                human_worker = CF::HumanWorker.new({:station => s, :number => number, :reward => reward, :stat_badge => stat_badge})
              end

              if worker['skill_badges'].present?
                skill_badges.each do |badge|
                  human_worker.badge = badge
                end
              end
              line.errors = human_worker.errors and return line if human_worker.errors.present?
            elsif worker_type =~ /robot/
              settings = worker['settings']
              robot_worker = CF::RobotWorker.create({:station => s, :type => worker_type, :settings => settings})

              line.errors = robot_worker.errors and return line if robot_worker.errors.present?
            else
              line.errors = ["Invalid worker type: #{worker_type}"]
              return line
            end

            # Creation of Form
            # Creation of TaskForm
            if station_file['station']['task_form'].present?
              title = station_file['station']['task_form']['form_title']
              instruction = station_file['station']['task_form']['instruction']
              form = CF::TaskForm.create({:station => s, :title => title, :instruction => instruction}) do |f|

                # Creation of FormFields
                line.errors = f.errors and return line if f.errors.present?

                station_file['station']['task_form']['form_fields'].each do |form_field|
                  form_field_params = form_field.merge(:form => f)
                  field = CF::FormField.new(form_field_params.symbolize_keys)

                  line.errors = field.errors and return line if field.errors.present?
                end

              end

            elsif station_file['station']['custom_task_form'].present?
              # Creation of CustomTaskForm
              title = station_file['station']['custom_task_form']['form_title']
              instruction = station_file['station']['custom_task_form']['instruction']

              html_file = station_file['station']['custom_task_form']['html']
              html = File.read("#{line_source}/station_#{station_file['station']['station_index']}/#{html_file}")
              css_file = station_file['station']['custom_task_form']['css']
              css = File.read("#{line_source}/station_#{station_file['station']['station_index']}/#{css_file}") if File.exist?("#{line_source}/station_#{s_index+1}/#{css_file}")
              js_file = station_file['station']['custom_task_form']['js']
              js = File.read("#{line_source}/station_#{station_file['station']['station_index']}/#{js_file}") if File.exist?("#{line_source}/station_#{s_index+1}/#{js_file}")
              form = CF::CustomTaskForm.create({:station => s, :title => title, :instruction => instruction, :raw_html => html, :raw_css => css, :raw_javascript => js})

              line.errors = form.errors and return line if form.errors.present?
            end

          end
        end

        output_formats = line_dump['output_formats'].presence
        if output_formats
          output_format = CF::OutputFormat.new(output_formats.merge(:line => line))

          line.errors = output_format.errors if output_format.errors.present?
        end

        return line
  end
end

