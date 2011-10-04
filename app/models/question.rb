class Question < ActiveRecord::Base
  belongs_to :term
  has_many :answers
end
