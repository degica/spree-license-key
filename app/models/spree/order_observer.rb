class Spree::OrderObserver < ActiveRecord::Observer
  def after_transition(order, transition)
    if transition.to == "complete" && order.paid?
      Rails.logger.info "Spree::OrderObserver called in SpreeLicenseKey"
      order.after_finalize!
    end
  end
end
