# frozen_string_literal: true

module CoreExtensions
  module String
    def integer?
      to_i.to_s == self
    end
  end
end
