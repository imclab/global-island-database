class AdminController < ApplicationController
  before_filter :authenticate
  before_filter :ensure_background_machine

  def index
    @layers = Layer.select("DISTINCT(email) AS email").order(:email)
    @generated_layer_files = [
      LayerFile.new(APP_CONFIG['cartodb_table'], Names::MANGROVE, Status::VALIDATED),
      LayerFile.new(APP_CONFIG['cartodb_table'], Names::CORAL, Status::VALIDATED),
      LayerFile.new(APP_CONFIG['cartodb_table'], Names::MANGROVE, Status::USER_EDITS),
      LayerFile.new(APP_CONFIG['cartodb_table'], Names::CORAL, Status::USER_EDITS)
    ]
  end

  def generate_from_cartodb
    job_params = {
      :cartodb_table => APP_CONFIG['cartodb_table'],
      :layer_name => params[:name].to_i,
      :layer_status => params[:status].to_i,
      :email => params[:email]
    }
    job_id = LayerFileJob.create(job_params)
    redirect_to({:action => :index, :job_id => job_id}.merge job_params)
    #output = LayerFile.new(APP_CONFIG['cartodb_table'], params[:name].to_i, params[:status].to_i, params[:email])
    #output.generate
    #send_file output.zip_path, :filename => output.zip_name, :type => "application/zip"
  end

  def download_from_cartodb
    output = LayerFile.new(APP_CONFIG['cartodb_table'], params[:name].to_i, params[:status].to_i, params[:email])
    send_file output.zip_path, :filename => output.zip_name, :type => "application/zip"
  end

 private
    def authenticate
      authenticate_with_http_basic { |u, p| !APP_CONFIG['admins'].select{ |a| a['login'] == u && a['password'] == p }.empty? } || request_http_basic_authentication
    end
    def ensure_background_machine
      puts request.host_with_port
      puts APP_CONFIG['background_machine']
      unless request.host_with_port == APP_CONFIG['background_machine']
        redirect_to "http://#{APP_CONFIG['background_machine']}/admin"
      end
    end
end
