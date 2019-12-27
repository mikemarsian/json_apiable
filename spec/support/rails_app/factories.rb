# frozen_string_literal: true
FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "test-#{n}@wecounsel.com" }
    name { 'Jon Snow' }
    date_of_birth { Date.parse('12/12/1980') }
  end
end