# == Schema Information
#
# Table name: banks
#
#  id           :bigint           not null, primary key
#  community_id :integer          not null
#  title        :string(255)      not null
#  status       :string(10)       default("enabled"), not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_banks_on_community_id  (community_id)
#

class Bank < ApplicationRecord

  belongs_to :community
  validates_presence_of :title

end
