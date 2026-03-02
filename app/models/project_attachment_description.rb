class ProjectAttachmentDescription < ApplicationRecord
  belongs_to :project
  belongs_to :attachment, class_name: "ActiveStorage::Attachment"

  validate :attachment_belongs_to_project

  private

  def attachment_belongs_to_project
    return if attachment.blank? || project.blank?
    return if attachment.record_type == "Project" && attachment.record_id == project_id

    errors.add(:attachment, "must belong to this project")
  end
end
