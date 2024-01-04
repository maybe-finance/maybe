class User < ApplicationRecord
  pay_customer stripe_attributes: :stripe_attributes, default_payment_processor: :stripe

  belongs_to :family
  has_many :connections, dependent: :destroy
  has_many :accounts, through: :connections
  has_many :messages
  has_many :conversations
  has_many :metrics

  accepts_nested_attributes_for :family
  
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :trackable, :omniauthable

  def stripe_attributes(pay_customer)
    {
      metadata: {
        pay_customer_id: pay_customer.id,
        user_id: id, # or pay_customer.owner_id
        family_id: self.family.id
      }
    }
  end

  def local_time_of_day
    # Should output Morning, Afternoon or Evening based on the user's local time, which is deteremined by the user's timezone

    location = Geocoder.search(current_sign_in_ip).first

    if location
      timezone_identifier = location.data['timezone']
      
      if timezone_identifier
        timezone = ActiveSupport::TimeZone[timezone_identifier]

        # Get the user's local time
        local_time = Time.now.in_time_zone(timezone)

        # Get the hour of the day
        hour = local_time.hour

        # Return the appropriate greeting
        if hour >= 3 && hour < 12
          "morning"
        elsif hour >= 12 && hour < 18
          "afternoon"
        else
          "evening"
        end
      else
        "morning"
      end
    else
      "morning"
    end
  end

end
