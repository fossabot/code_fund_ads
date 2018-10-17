# == Schema Information
#
# Table name: audiences
#
#  id                    :uuid             not null, primary key
#  name                  :string(255)      not null
#  programming_languages :string(255)      default([]), is an Array
#  inserted_at           :datetime         not null
#  updated_at            :datetime         not null
#  topic_categories      :string(255)      default([]), is an Array
#  fallback_campaign_id  :uuid
#

require 'test_helper'

class AudienceTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
