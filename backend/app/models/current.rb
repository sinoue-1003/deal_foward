# ActiveSupport::CurrentAttributes — リクエストスコープのテナント/ユーザーコンテキスト
#
# 使い方:
#   Current.tenant   # => Tenant インスタンス or nil
#   Current.user     # => User インスタンス or nil
class Current < ActiveSupport::CurrentAttributes
  attribute :tenant, :user
end
