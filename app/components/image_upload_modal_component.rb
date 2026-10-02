# frozen_string_literal: true

class ImageUploadModalComponent < ViewComponent::Base
  def initialize(product:, image:, variant: nil, error_target: nil)
    @product = product
    @image = image
    @variant = variant
    @error_target = error_target || image
  end

  private

  attr_reader :product, :image, :variant, :error_target

  def viewable
    variant || product
  end

  def resource_name
    helpers.image_modal_resource_name(variant, product)
  end

  def preview_url
    image.persisted? ? image.url(:large) : Spree::Image.default_image_url(:large)
  end
end
