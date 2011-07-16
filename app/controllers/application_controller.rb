class ApplicationController < ActionController::Base
  before_filter :check_uri
  before_filter :authenticate_user!

  helper :all

  protect_from_forgery
  include ApplicationHelper  
  def check_uri

    if /^www\./.match(request.host_with_port)
      host = request.host_with_port.gsub(/^www\./, "")
      redirect_loc = request.protocol + host + request.path
      redirect_logger.info("\n#{Time.now.to_s(:db)}\nredirect to: #{redirect_loc}\n")

      redirect_to redirect_loc
    end
  end

  def redirect_logger
    @@redirect_logger ||= Logger.new("#{::Rails.root.to_s}/log/redirect.log")
  end

  private
  def set_abingo_identity
    if request.user_agent =~ /\b(Baidu|Gigabot|Googlebot|libwww-perl|lwp-trivial|msnbot|SiteUptime|Slurp|WordPress|ZIBB|ZyBorg)\b/i
      Abingo.identity = "robot"
    elsif current_user
      Abingo.identity = current_user.id
    else
      session[:abingo_identity] ||= rand(10 ** 10)
      Abingo.identity = session[:abingo_identity]
    end
  end

end