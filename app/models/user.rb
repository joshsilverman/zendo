class User < ActiveRecord::Base
  
#  validates_length_of :first_name, :minimum => 1
#  validates_length_of :last_name, :minimum => 1
  validates :username, :length => {:minimum => 3,
                               :maximum => 20,
                               :message => "Name must be between 3-20 characters"},
                   :format => {:with => /^\w+[^\s]$/,
                               :message => "Please use only letters numbers and underscores _"},
                   :uniqueness => true,
                   :allow_nil => true

  has_many :authentications, :dependent => :destroy
  #has_many :documents
  has_many :tags
  has_many :mems
  has_many :terms
  has_many :reps
  has_many :shares
  #has_and_belongs_to_many :vdocs, :class_name => "Document", :uniq => true
  	
  has_many :userships
  has_many :documents, :through => :userships, :uniq => true
  #has_many :documents, :through => :userships
  

  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable, :lockable and :timeoutable
  devise :database_authenticatable, :registerable, 
         :recoverable, :rememberable, :trackable, :validatable, 
         :token_authenticatable, :lockable, :timeoutable #, :confirmable
  
  # Setup accessible (or protected) attributes for your model
  attr_accessible :first_name, :last_name, :email, :username, :password, :password_confirmation

  def apply_omniauth(omniauth)

    if (!omniauth['user_info']['email'].nil?)
      self.email = omniauth['user_info']['email']
    elsif omniauth['extra'] && email.blank?
        self.email = omniauth['extra']['user_hash']['email']
    end
    
    self.first_name = omniauth['user_info']['first_name'] if first_name.blank?
    self.last_name = omniauth['user_info']['last_name'] if last_name.blank?

    # seed password with random string
    self.password = ActiveSupport::SecureRandom.hex(16)[0,20]

    authentications.build(:provider => omniauth['provider'], :uid => omniauth['uid'])
  end

  def password_required?
    (authentications.empty? || !password.blank?) && super
  end

end
