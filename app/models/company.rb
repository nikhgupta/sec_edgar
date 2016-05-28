class Company < ActiveRecord::Base
  has_many :reports

  validates_uniqueness_of :symbol
end
