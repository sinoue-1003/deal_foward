class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  # テナントスコープ: サブクラスで belongs_to :tenant を宣言すると自動的に
  # Current.tenant が設定されている場合に tenant_id を付与する
  def self.inherited(subclass)
    super
    subclass.instance_eval do
      before_create :assign_current_tenant, if: -> { respond_to?(:tenant_id=) && Current.tenant.present? }
    end
  end

  private

  def assign_current_tenant
    self.tenant_id ||= Current.tenant&.id
  end
end
