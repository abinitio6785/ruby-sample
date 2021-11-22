# == Schema Information
#
# Table name: listing_packages
#
#  id                  :bigint           not null, primary key
#  package_name        :string(255)
#  package_description :text(65535)
#  package_price       :decimal(10, )
#  package_discount    :decimal(10, )
#  listing_id          :integer
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  package_status      :boolean
#  package_type        :integer          default("normal")
#  buyer_id            :string(255)
#  tiktok_share        :boolean          default(FALSE)
#  insta_share         :boolean          default(FALSE)
#  facebook_share      :boolean          default(FALSE)
#

class ListingPackage < ApplicationRecord
  belongs_to :listing
  has_many :listing_package_attachments
  scope :unapproved_packages, -> { where(package_status: [false, nil]) }
  scope :approved_packages, -> { where(package_status: [true, nil]) }
  scope :packages_without_custom, -> { where.not(package_type: true) }
  #scope :packages_with_custom, ->(buyer_id) { where(package_status: [true, nil]) }

  scope :packages_with_custom, ->(current_user) do
    #buyer_id.present? ? where.(buyer_id: buyer_id) : nil
    exclude_self(current_user)
  end

  scope :exclude_self, ->(current_user) do
    current_user.persisted? ? where("`listing_packages`.`buyer_id` = :buyer_id OR
      `listing_packages`.`package_status` = TRUE OR `listing_packages`.`package_status` IS NULL", buyer_id: current_user.id) : where(package_status: [true, nil])
  end

  # define package type
  enum package_type: ["normal","custom"]
end
