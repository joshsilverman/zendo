class ApplicationController < ActionController::Base
  before_filter :check_uri
  before_filter :authenticate_user!
  # before_filter :check_headers

  helper :all

  protect_from_forgery
  include ApplicationHelper

#  def check_headers
#    puts request.env
#    @headers |= request.env.inject({}) { |h, (k, v)|
#      if k =~ /^(HTTP|CONTENT)_/ then
#        h[k.sub(/^HTTP_/, '').dasherize.gsub(/([^\-]+)/) { $1.capitalize }] = v
#      end
#      h    
#    }
#  end

  def check_uri

    if /^www\./.match(request.host_with_port)
      host = request.host_with_port.gsub(/^www\./, "")
      redirect_loc = request.protocol + host + request.path
      redirect_logger.info("\n#{Time.now.to_s(:db)}\nredirect to: #{redirect_loc}\n")

      redirect_to redirect_loc
    end

    if request.path == "/user"
      redirect_loc = request.protocol + request.host_with_port + "/my_eggs"
      redirect_to redirect_loc
    end
  end

  def redirect_logger
    @@redirect_logger ||= Logger.new("#{::Rails.root.to_s}/log/redirect.log")
  end
  
  def check_admin
    redirect_to "/my_eggs" unless current_user.try(:admin?)
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

  def mobile_device?
    @mobile = false
    ## Check if iPhone
    if request.user_agent.include? 'iPhone'
      @mobile = true
      end
    ## Check if Android
    if request.user_agent.include? 'android'
      @mobile = true
    end
    return @mobile
  end

  helper_method :mobile_device?

  def get_phase(strength, mc, fita)
    phase = 1
    if strength > 120000 # 1/2 a week
      phase = 2
      if strength > 300000   #1 day
        phase = 3
        if strength > 1000000   #1 hour
          phase = 4
        end
      end
    end
    case phase
    when 1
      @phase = 2 #will be set back to 1 when chunked learning is introduced
    when 2
      if mc.size > 2
        @phase = 2
      else
        @phase = 4
      end
    when 3
        @phase = 4
    when 4
      @phase = 4
    else
      puts "There was an error with the phase"
    end
  end
end