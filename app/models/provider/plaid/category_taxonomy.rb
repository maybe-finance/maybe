# https://plaid.com/documents/transactions-personal-finance-category-taxonomy.csv
module Provider::Plaid::CategoryTaxonomy
  CATEGORIES_MAP = {
    income: {
      classification: :income,
      aliases: [ "income", "revenue", "earnings" ],
      detailed_categories: {
        income_dividends: {
          classification: :income,
          aliases: [ "dividend", "stock income", "dividend income", "dividend earnings" ]
        },
        income_interest_earned: {
          classification: :income,
          aliases: [ "interest", "bank interest", "interest earned", "interest income" ]
        },
        income_retirement_pension: {
          classification: :income,
          aliases: [ "retirement", "pension" ]
        },
        income_tax_refund: {
          classification: :income,
          aliases: [ "tax refund" ]
        },
        income_unemployment: {
          classification: :income,
          aliases: [ "unemployment" ]
        },
        income_wages: {
          classification: :income,
          aliases: [ "wage", "salary", "paycheck" ]
        },
        income_other_income: {
          classification: :income,
          aliases: [ "other income", "misc income" ]
        }
      }
    },
    loan_payments: {
      classification: :expense,
      aliases: [ "loan payment", "debt payment", "loan", "debt", "payment" ],
      detailed_categories: {
        loan_payments_car_payment: {
          classification: :expense,
          aliases: [ "car payment", "auto loan" ]
        },
        loan_payments_credit_card_payment: {
          classification: :expense,
          aliases: [ "credit card", "card payment" ]
        },
        loan_payments_personal_loan_payment: {
          classification: :expense,
          aliases: [ "personal loan", "loan payment" ]
        },
        loan_payments_mortgage_payment: {
          classification: :expense,
          aliases: [ "mortgage", "home loan" ]
        },
        loan_payments_student_loan_payment: {
          classification: :expense,
          aliases: [ "student loan", "education loan" ]
        },
        loan_payments_other_payment: {
          classification: :expense,
          aliases: [ "loan", "loan payment" ]
        }
      }
    },
    bank_fees: {
      classification: :expense,
      aliases: [ "bank fee", "service charge", "fee", "misc fees" ],
      detailed_categories: {
        bank_fees_atm_fees: {
          classification: :expense,
          aliases: [ "atm fee", "withdrawal fee" ]
        },
        bank_fees_foreign_transaction_fees: {
          classification: :expense,
          aliases: [ "foreign fee", "international fee" ]
        },
        bank_fees_insufficient_funds: {
          classification: :expense,
          aliases: [ "nsf fee", "overdraft" ]
        },
        bank_fees_interest_charge: {
          classification: :expense,
          aliases: [ "interest charge", "finance charge" ]
        },
        bank_fees_overdraft_fees: {
          classification: :expense,
          aliases: [ "overdraft fee" ]
        },
        bank_fees_other_bank_fees: {
          classification: :expense,
          aliases: [ "bank fee", "service charge" ]
        }
      }
    },
    entertainment: {
      classification: :expense,
      aliases: [ "entertainment", "recreation" ],
      detailed_categories: {
        entertainment_casinos_and_gambling: {
          classification: :expense,
          aliases: [ "casino", "gambling" ]
        },
        entertainment_music_and_audio: {
          classification: :expense,
          aliases: [ "music", "concert" ]
        },
        entertainment_sporting_events_amusement_parks_and_museums: {
          classification: :expense,
          aliases: [ "event", "amusement", "museum" ]
        },
        entertainment_tv_and_movies: {
          classification: :expense,
          aliases: [ "movie", "streaming" ]
        },
        entertainment_video_games: {
          classification: :expense,
          aliases: [ "game", "gaming" ]
        },
        entertainment_other_entertainment: {
          classification: :expense,
          aliases: [ "entertainment", "recreation" ]
        }
      }
    },
    food_and_drink: {
      classification: :expense,
      aliases: [ "food", "dining", "food and drink", "food & drink" ],
      detailed_categories: {
        food_and_drink_beer_wine_and_liquor: {
          classification: :expense,
          aliases: [ "alcohol", "liquor", "beer", "wine", "bar", "pub" ]
        },
        food_and_drink_coffee: {
          classification: :expense,
          aliases: [ "coffee", "cafe", "coffee shop" ]
        },
        food_and_drink_fast_food: {
          classification: :expense,
          aliases: [ "fast food", "takeout" ]
        },
        food_and_drink_groceries: {
          classification: :expense,
          aliases: [ "grocery", "supermarket", "grocery store" ]
        },
        food_and_drink_restaurant: {
          classification: :expense,
          aliases: [ "restaurant", "dining" ]
        },
        food_and_drink_vending_machines: {
          classification: :expense,
          aliases: [ "vending" ]
        },
        food_and_drink_other_food_and_drink: {
          classification: :expense,
          aliases: [ "food", "drink" ]
        }
      }
    },
    general_merchandise: {
      classification: :expense,
      aliases: [ "shopping", "retail" ],
      detailed_categories: {
        general_merchandise_bookstores_and_newsstands: {
          classification: :expense,
          aliases: [ "book", "newsstand" ]
        },
        general_merchandise_clothing_and_accessories: {
          classification: :expense,
          aliases: [ "clothing", "apparel" ]
        },
        general_merchandise_convenience_stores: {
          classification: :expense,
          aliases: [ "convenience" ]
        },
        general_merchandise_department_stores: {
          classification: :expense,
          aliases: [ "department store" ]
        },
        general_merchandise_discount_stores: {
          classification: :expense,
          aliases: [ "discount store" ]
        },
        general_merchandise_electronics: {
          classification: :expense,
          aliases: [ "electronic", "computer" ]
        },
        general_merchandise_gifts_and_novelties: {
          classification: :expense,
          aliases: [ "gift", "souvenir" ]
        },
        general_merchandise_office_supplies: {
          classification: :expense,
          aliases: [ "office supply" ]
        },
        general_merchandise_online_marketplaces: {
          classification: :expense,
          aliases: [ "online shopping" ]
        },
        general_merchandise_pet_supplies: {
          classification: :expense,
          aliases: [ "pet supply", "pet food" ]
        },
        general_merchandise_sporting_goods: {
          classification: :expense,
          aliases: [ "sporting good", "sport" ]
        },
        general_merchandise_superstores: {
          classification: :expense,
          aliases: [ "superstore", "retail" ]
        },
        general_merchandise_tobacco_and_vape: {
          classification: :expense,
          aliases: [ "tobacco", "smoke" ]
        },
        general_merchandise_other_general_merchandise: {
          classification: :expense,
          aliases: [ "shopping", "merchandise" ]
        }
      }
    },
    home_improvement: {
      classification: :expense,
      aliases: [ "home", "house", "house renovation", "home improvement", "renovation" ],
      detailed_categories: {
        home_improvement_furniture: {
          classification: :expense,
          aliases: [ "furniture", "furnishing" ]
        },
        home_improvement_hardware: {
          classification: :expense,
          aliases: [ "hardware", "tool" ]
        },
        home_improvement_repair_and_maintenance: {
          classification: :expense,
          aliases: [ "repair", "maintenance" ]
        },
        home_improvement_security: {
          classification: :expense,
          aliases: [ "security", "alarm" ]
        },
        home_improvement_other_home_improvement: {
          classification: :expense,
          aliases: [ "home improvement", "renovation" ]
        }
      }
    },
    medical: {
      classification: :expense,
      aliases: [ "medical", "healthcare", "health" ],
      detailed_categories: {
        medical_dental_care: {
          classification: :expense,
          aliases: [ "dental", "dentist" ]
        },
        medical_eye_care: {
          classification: :expense,
          aliases: [ "eye", "optometrist" ]
        },
        medical_nursing_care: {
          classification: :expense,
          aliases: [ "nursing", "care" ]
        },
        medical_pharmacies_and_supplements: {
          classification: :expense,
          aliases: [ "pharmacy", "prescription" ]
        },
        medical_primary_care: {
          classification: :expense,
          aliases: [ "doctor", "medical" ]
        },
        medical_veterinary_services: {
          classification: :expense,
          aliases: [ "vet", "veterinary" ]
        },
        medical_other_medical: {
          classification: :expense,
          aliases: [ "medical", "healthcare" ]
        }
      }
    },
    personal_care: {
      classification: :expense,
      aliases: [ "personal care", "grooming" ],
      detailed_categories: {
        personal_care_gyms_and_fitness_centers: {
          classification: :expense,
          aliases: [ "gym", "fitness", "exercise", "sport" ]
        },
        personal_care_hair_and_beauty: {
          classification: :expense,
          aliases: [ "salon", "beauty" ]
        },
        personal_care_laundry_and_dry_cleaning: {
          classification: :expense,
          aliases: [ "laundry", "cleaning" ]
        },
        personal_care_other_personal_care: {
          classification: :expense,
          aliases: [ "personal care", "grooming" ]
        }
      }
    },
    general_services: {
      classification: :expense,
      aliases: [ "service", "professional service" ],
      detailed_categories: {
        general_services_accounting_and_financial_planning: {
          classification: :expense,
          aliases: [ "accountant", "financial advisor" ]
        },
        general_services_automotive: {
          classification: :expense,
          aliases: [ "auto repair", "mechanic", "vehicle", "car", "car care", "car maintenance", "vehicle maintenance" ]
        },
        general_services_childcare: {
          classification: :expense,
          aliases: [ "childcare", "daycare" ]
        },
        general_services_consulting_and_legal: {
          classification: :expense,
          aliases: [ "legal", "attorney" ]
        },
        general_services_education: {
          classification: :expense,
          aliases: [ "education", "tuition" ]
        },
        general_services_insurance: {
          classification: :expense,
          aliases: [ "insurance", "premium" ]
        },
        general_services_postage_and_shipping: {
          classification: :expense,
          aliases: [ "shipping", "postage" ]
        },
        general_services_storage: {
          classification: :expense,
          aliases: [ "storage" ]
        },
        general_services_other_general_services: {
          classification: :expense,
          aliases: [ "service" ]
        }
      }
    },
    government_and_non_profit: {
      classification: :expense,
      aliases: [ "government", "non-profit" ],
      detailed_categories: {
        government_and_non_profit_donations: {
          classification: :expense,
          aliases: [ "donation", "charity", "charitable", "charitable donation", "giving", "gifts and donations", "gifts & donations" ]
        },
        government_and_non_profit_government_departments_and_agencies: {
          classification: :expense,
          aliases: [ "government", "agency" ]
        },
        government_and_non_profit_tax_payment: {
          classification: :expense,
          aliases: [ "tax payment", "tax" ]
        },
        government_and_non_profit_other_government_and_non_profit: {
          classification: :expense,
          aliases: [ "government", "non-profit" ]
        }
      }
    },
    transportation: {
      classification: :expense,
      aliases: [ "transportation", "travel" ],
      detailed_categories: {
        transportation_bikes_and_scooters: {
          classification: :expense,
          aliases: [ "bike", "scooter" ]
        },
        transportation_gas: {
          classification: :expense,
          aliases: [ "gas", "fuel" ]
        },
        transportation_parking: {
          classification: :expense,
          aliases: [ "parking" ]
        },
        transportation_public_transit: {
          classification: :expense,
          aliases: [ "transit", "bus" ]
        },
        transportation_taxis_and_ride_shares: {
          classification: :expense,
          aliases: [ "taxi", "rideshare" ]
        },
        transportation_tolls: {
          classification: :expense,
          aliases: [ "toll" ]
        },
        transportation_other_transportation: {
          classification: :expense,
          aliases: [ "transportation", "travel" ]
        }
      }
    },
    travel: {
      classification: :expense,
      aliases: [ "travel", "vacation", "trip", "sabbatical" ],
      detailed_categories: {
        travel_flights: {
          classification: :expense,
          aliases: [ "flight", "airfare" ]
        },
        travel_lodging: {
          classification: :expense,
          aliases: [ "hotel", "lodging" ]
        },
        travel_rental_cars: {
          classification: :expense,
          aliases: [ "rental car" ]
        },
        travel_other_travel: {
          classification: :expense,
          aliases: [ "travel", "trip" ]
        }
      }
    },
    rent_and_utilities: {
      classification: :expense,
      aliases: [ "utilities", "housing", "house", "home", "rent", "rent & utilities" ],
      detailed_categories: {
        rent_and_utilities_gas_and_electricity: {
          classification: :expense,
          aliases: [ "utility", "electric" ]
        },
        rent_and_utilities_internet_and_cable: {
          classification: :expense,
          aliases: [ "internet", "cable" ]
        },
        rent_and_utilities_rent: {
          classification: :expense,
          aliases: [ "rent", "lease" ]
        },
        rent_and_utilities_sewage_and_waste_management: {
          classification: :expense,
          aliases: [ "sewage", "waste" ]
        },
        rent_and_utilities_telephone: {
          classification: :expense,
          aliases: [ "phone", "telephone" ]
        },
        rent_and_utilities_water: {
          classification: :expense,
          aliases: [ "water" ]
        },
        rent_and_utilities_other_utilities: {
          classification: :expense,
          aliases: [ "utility" ]
        }
      }
    }
  }
end
