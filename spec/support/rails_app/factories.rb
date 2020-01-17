require 'faker'

# frozen_string_literal: true
FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    name { Faker::Book.author }
    date_of_birth { Faker::Date.birthday(min_age: 18, max_age: 65) }
  end

  factory :post do
    title { Faker::Book.title }
    text { Faker::Quote.famous_last_words }
    association :author, factory: :user
  end

  factory :comment do
    body { Faker::Quotes::Shakespeare.hamlet_quote }
    association :commenter, factory: :user
    association :post, factory: :post
  end

  factory :address do
    association :user, factory: :user
    street { Faker::Address.street_name }
    city { Faker::Address.city }
    state_code { Faker::Address.state_abbr }
    zip_code { Faker::Address.zip_code  }
    country_code { 'US'  }
  end
end