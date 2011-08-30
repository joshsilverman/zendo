class AbingoDashController < ApplicationController
  before_filter :check_admin

  include Abingo::Controller::Dashboard
end
