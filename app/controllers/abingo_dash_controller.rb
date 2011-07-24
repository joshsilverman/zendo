class AbingoDashController < ApplicationController
  before_filter :check_admin
  def check_admin
    puts 'ADMIN CHECK'
    unless current_user.try(:admin?)
      redirect_to "/dashboard"
    end
  end

  include Abingo::Controller::Dashboard
end
