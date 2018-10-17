# == Schema Information
#
# Table name: assets
#
#  user_id      :uuid
#  id           :uuid             not null, primary key
#  name         :string(255)      not null
#  image_object :string(255)      not null
#  image_bucket :string(255)      not null
#  inserted_at  :datetime         not null
#  updated_at   :datetime         not null
#  height       :integer
#  width        :integer
#

class Asset < ApplicationRecord
  # extends ...................................................................
  # includes ..................................................................

  # relationships .............................................................
  #belongs_to :user

  # validations ...............................................................
  validates :image_bucket, length: { maximum: 255, allow_blank: false }
  validates :image_object, length: { maximum: 255, allow_blank: false }
  validates :name, length: { maximum: 255, allow_blank: false }

  # callbacks .................................................................
  # scopes ....................................................................
  # additional config (i.e. accepts_nested_attribute_for etc...) ..............

  # class methods .............................................................
  class << self
  end

  # public instance methods ...................................................

  # protected instance methods ................................................
  protected

  # private instance methods ..................................................
  private
end
