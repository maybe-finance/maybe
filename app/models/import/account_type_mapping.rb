class Import::AccountTypeMapping < Import::Mapping
  validates :value, presence: true
  validates :value, inclusion: Accountable::TYPES

  def accountable
    Accountable.from_type(value).new
  end
end
