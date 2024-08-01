# frozen_string_literal: true

module Admin
  module ProductsHelper
    def product_image_form_path(product)
      if product.image.present?
        edit_admin_product_image_path(product.id, product.image.id)
      else
        new_admin_product_image_path(product.id)
      end
    end

    def prepare_new_variant(product)
      product.variants.build do |variant|
        # variant.unit_value = 1.0 * (product.variant_unit_scale || 1)
        variant.unit_presentation = VariantUnits::OptionValueNamer.new(variant).name
      end
    end

    def unit_value_with_description(variant)
      precised_unit_value = nil

      if variant.unit_value
        scaled_unit_value = variant.unit_value / (variant.product.variant_unit_scale || 1)
        precised_unit_value = number_with_precision(
          scaled_unit_value,
          precision: nil,
          strip_insignificant_zeros: true
        )
      end

      [precised_unit_value, variant.unit_description].compact_blank.join(" ")
    end
  end
end
