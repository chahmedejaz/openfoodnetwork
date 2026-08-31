# frozen_string_literal: true

# Images used to be soft-deleted so that a single-product-image constraint could be
# enforced before multi-image backoffice support was ready. Nothing ever read those
# rows back, and the model deliberately suppressed ActiveStorage's dependent-purge,
# so every soft-deleted image left a spree_assets row, an attachment row and a blob
# behind. Now that soft delete is gone, remove them for good.
#
# This has to run before deleted_at is dropped: that column is the only way to tell
# these rows apart from live images.
class PurgeSoftDeletedImages < ActiveRecord::Migration[7.2]
  class Asset < ActiveRecord::Base
    self.table_name = "spree_assets"
    self.inheritance_column = :_type_disabled
  end

  class Attachment < ActiveRecord::Base
    self.table_name = "active_storage_attachments"
  end

  def up
    Asset.where.not(deleted_at: nil).find_each do |image|
      # Spree::Image is STI under Spree::Asset, so ActiveStorage stores the base
      # class name as the record_type.
      attachment = Attachment.find_by(
        name: "attachment",
        record_type: "Spree::Asset",
        record_id: image.id
      )

      unless attachment
        image.destroy!
        next
      end

      blob_id = attachment.blob_id

      attachment.destroy!
      image.destroy!

      # Another attachment may still reference the same blob; only purge an orphan.
      if !Attachment.where(blob_id:).exists?
        ActiveStorage::Blob.find_by(id: blob_id)&.purge_later
      end

      Rails.logger.info(
        "Purged soft-deleted image ##{image.id} and its associated attachment and blob."
      )
    rescue StandardError => e
      Rails.logger.error(
        "Failed to purge soft-deleted image ##{image.id}: #{e.class}: #{e.message}"
      )
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
