# == Schema Information
#
# Table name: listing_attachments
#
#  id                :bigint           not null, primary key
#  file_file_name    :string(255)
#  file_content_type :string(255)
#  file_file_size    :integer
#  file_updated_at   :datetime
#  listing_id        :bigint
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
# Indexes
#
#  index_listing_attachments_on_listing_id  (listing_id)
#

class ListingAttachment < ApplicationRecord

  belongs_to :listing

  has_attached_file :file
  do_not_validate_attachment_file_type :file

  def image?
    file_content_type =~ %r{^(image|(x-)?application)/(bmp|gif|jpeg|jpg|pjpeg|png|x-png)$} ? true : false
  end

  def pdf?
    file_content_type == "application/pdf"
  end

  def file?
    !image? && !pdf?
  end

  def type
    return 'image' if image?
    return 'pdf' if pdf?
    return 'file' if file?
  end

  def to_jq_upload
    {
      url: file.url,
      delete_url: id,
      file_id: id,
      delete_type: "DELETE"
    }.to_json
  end
end
