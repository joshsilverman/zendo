class StaticController < ApplicationController
  before_filter :authenticate_user!, :only => []

  def mission
  end

  def story
  end

  def team
  end

  def contact
  end
  
  def returns
    
  end
end