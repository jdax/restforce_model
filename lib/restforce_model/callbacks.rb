require 'active_support/concern'
require 'active_model/callbacks'

module RestforceModel::Callbacks
  extend ActiveSupport::Concern
  include ActiveModel::Callbacks

  included do
    define_model_callbacks :save, :update, :commit, :destroy
  end
end
