# == Schema Information
#
# Table name: people_categories
#
#  id          :bigint           not null, primary key
#  category_id :bigint
#  author_id   :string(255)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_people_categories_on_author_id    (author_id)
#  index_people_categories_on_category_id  (category_id)
#

class PeopleCategory < ApplicationRecord
  belongs_to :category
  belongs_to :author, :class_name => "Person"
end
