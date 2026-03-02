class ProjectChange < ApplicationRecord
  belongs_to :project
  has_many_attached :images

  before_validation :set_changed_at, on: :create

  validates :description, presence: true, length: { minimum: 5 }
  validates :changed_at, presence: true

  private

  def set_changed_at
    self.changed_at = Time.current
  end
end
