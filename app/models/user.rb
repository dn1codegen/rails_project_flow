class User < ApplicationRecord
  has_secure_password

  has_many :projects, dependent: :destroy

  before_validation :normalize_email

  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :email,
    presence: true,
    uniqueness: { case_sensitive: false },
    format: { with: URI::MailTo::EMAIL_REGEXP }

  private

  def normalize_email
    self.email = email.to_s.downcase.strip
  end
end
