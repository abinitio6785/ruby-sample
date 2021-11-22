# == Schema Information
#
# Table name: people_images
#
#  id                 :bigint           not null, primary key
#  author_id          :string(255)
#  image_file_name    :string(255)
#  image_content_type :string(255)
#  image_file_size    :integer
#  image_updated_at   :datetime
#  width              :integer
#  height             :integer
#  position           :integer          default(0)
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
# Indexes
#
#  index_people_images_on_author_id  (author_id)
#

class PeopleImage < ApplicationRecord

  belongs_to :author, :class_name => "Person"

  # see paperclip (for image_processing column)
  has_attached_file :image,
    :styles => {
      :small_3x2 => "240x160#",
      :medium => "360x270#",
      :thumb => "120x120#",
      :original => "#{APP_CONFIG.original_image_width}x#{APP_CONFIG.original_image_height}>",
      :big => Proc.new { |instance| instance.crop_big },
      :square => "408x408#",
      :square_2x => "816x816#"}

  before_image_post_process :set_dimensions

  before_create :set_position

  process_in_background :image, :processing_image_url => "/assets/listing_image/processing.png", :priority => 1
  validates_attachment_size :image, :less_than => APP_CONFIG.max_image_filesize.to_i, :unless => Proc.new {|model| model.image.nil? }
  validates_attachment_content_type :image,
                                    :content_type => IMAGE_CONTENT_TYPE,
                                    :unless => Proc.new {|model| model.image.nil? }


  def get_dimensions_for_style(style)
    case style
    when :small_3x2
      {width: 240, height: 160}
    when :medium
      {width: 360, height: 270}
    when :big
      {width: 660, height: 440}
    when :thumb
      {width: 120, height: 120}
    when :email
      {width: 150, height: 100}
    when :square
      {width: 408, height: 408}
    when :square_2x
      {width: 816, height: 816}
    when :original
      raise NotImplementedError.new("This feature is not implemented yet for style: #{style}")
    else
      raise ArgumentError.new("Unknown style: #{style}")
    end
  end

  def set_dimensions
    # Silently return, if there's no `width` and `height`
    # Prevents old migrations from crashing
    return true unless self.respond_to?(:width) && self.respond_to?(:height)

    return true if self.width.present? && self.height.present?

    # guard against malformed images or bugs in ImageMagick library
    begin
      geometry = extract_dimensions
    rescue Paperclip::Errors::NotIdentifiedByImageMagickError => error
      self.error = error.message
      return false
    end

    if geometry
      self.width = geometry.width.to_i
      self.height = geometry.height.to_i
    end

    return true
  end

  def crop_big
    geometry = Paperclip::Geometry.from_file(Paperclip.io_adapters.for(image.queued_for_write[:original]))
    max_crop_percentage = 0.2
    ListingImage.construct_big_style({:width => geometry.width.round, :height => geometry.height.round}, {:width => 660, :height => 440}, max_crop_percentage)
  end

  # Retrieves dimensions for image assets
  # @note Do this after resize operations to account for auto-orientation.
  # https://github.com/thoughtbot/paperclip/wiki/Extracting-image-dimensions
  def extract_dimensions
    return unless image_downloaded

    tempfile = image.queued_for_write[:original]

    # Works with uploaded files and existing files
    path_or_url = if !tempfile.nil? then
      # Uploading new file
      tempfile.path
    else
      if image.options[:storage] === :s3
        image.url
      else
        image.path
      end
    end

    geometry = Paperclip::Geometry.from_file(path_or_url)
    geometry.auto_orient
    geometry
  end

  def correct_size?(aspect_ratio)
    ListingImage.correct_size? self.width, self.height, aspect_ratio
  end

  def too_narrow?(aspect_ratio)
    ListingImage.too_narrow? self.width, self.height, aspect_ratio
  end

  def too_wide?(aspect_ratio)
    ListingImage.too_wide? self.width, self.height, aspect_ratio
  end

  def self.correct_size?(width, height, aspect_ratio)
    width.to_f / height.to_f == aspect_ratio.to_f
  end

  def self.too_narrow?(width, height, aspect_ratio)
    width.to_f / height.to_f < aspect_ratio.to_f
  end

  def self.too_wide?(width, height, aspect_ratio)
    width.to_f / height.to_f > aspect_ratio.to_f
  end

  def image_ready?
    image_downloaded && !image_processing
  end

  def self.crop_need(x, desired_x)
    x - desired_x
  end

  def self.crop_need_percentage(x, desired_x)
    self.crop_need(x, desired_x).to_f / x.to_f
  end

  def self.should_crop?(dimensions, desired_dimensions, max_crop_difference)
    scaled = self.scale_to_cover(dimensions, desired_dimensions)

    width_crop_need = crop_need_percentage(scaled[:width], desired_dimensions[:width])
    height_crop_need = crop_need_percentage(scaled[:height], desired_dimensions[:height])

    width_crop_need <= max_crop_difference && height_crop_need <= max_crop_difference
  end

  def self.scale_by(source, target, by)
    scale_factor = source[by] / target[by].to_f
      {
        :width => (source[:width] / scale_factor),
        :height => (source[:height] / scale_factor)
      }
  end

  def self.scale_to_cover(dimensions, area_to_cover)
    scaled_width = self.scale_by(dimensions, area_to_cover, :width)
    scaled_width_height = if scaled_width[:height] < area_to_cover[:height]
      self.scale_by(scaled_width, area_to_cover, :height)
    else
      scaled_width
    end

    return scaled_width_height
  end

  def self.construct_big_style(dimensions, desired_dimensions, max_crop_difference)
    default_style = "#{desired_dimensions[:width]}x#{desired_dimensions[:height]}>"
    crop_style = "#{desired_dimensions[:width]}x#{desired_dimensions[:height]}#"

    if self.should_crop?(dimensions, desired_dimensions, max_crop_difference)
      crop_style
    else
      default_style
    end
  end

  def set_position
    self.position = ListingImage.where(listing_id: listing_id).maximum(:position).to_i + 1
  end
end
