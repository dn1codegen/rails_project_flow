class Project < ApplicationRecord
  SHARE_LINK_LIFETIME = 4.days

  belongs_to :user
  has_many :project_changes, -> { order(changed_at: :desc, created_at: :desc) }, dependent: :destroy
  has_many :project_attachment_descriptions, dependent: :destroy
  has_one_attached :cover_image
  has_many_attached :measurement_images
  has_many_attached :example_files
  has_many_attached :installation_photos

  before_validation :sync_title_with_product

  validates :product, presence: true, length: { minimum: 3, maximum: 120 }, on: :create
  validates :product, length: { minimum: 3, maximum: 120 }, allow_blank: true
  validates :description, presence: true, length: { minimum: 10 }
  validates :share_token, uniqueness: true, allow_nil: true

  def display_name
    product.presence || title
  end

  def attachment_description_for(attachment)
    attachment_descriptions_by_attachment_id[attachment.id]
  end

  def active_share_link?(now: Time.current)
    share_token.present? && share_token_expires_at.present? && share_token_expires_at > now
  end

  def share_link_remaining_seconds(now: Time.current)
    return 0 unless share_token_expires_at.present?

    [ (share_token_expires_at - now).ceil, 0 ].max
  end

  def regenerate_share_link!(now: Time.current)
    update!(
      share_token: generate_unique_share_token,
      share_token_expires_at: now + SHARE_LINK_LIFETIME
    )
  end

  private

  def sync_title_with_product
    cleaned_product = product.to_s.strip
    return if cleaned_product.blank?

    self.product = cleaned_product
    self.title = cleaned_product
  end

  def attachment_descriptions_by_attachment_id
    @attachment_descriptions_by_attachment_id ||=
      project_attachment_descriptions.index_by(&:attachment_id).transform_values(&:description)
  end

  def generate_unique_share_token
    loop do
      token = SecureRandom.urlsafe_base64(24)
      break token unless self.class.exists?(share_token: token)
    end
  end
end
