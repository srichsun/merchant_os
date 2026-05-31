# frozen_string_literal: true

class ProductPolicy < ApplicationPolicy
  # Everyone in the store can view and edit products...
  def index?
    true
  end

  def show?
    true
  end

  def create?
    true
  end

  def update?
    true
  end

  # ...but only the owner can delete them
  def destroy?
    user.owner?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      # acts_as_tenant already scopes to the current store
      scope.all
    end
  end
end
