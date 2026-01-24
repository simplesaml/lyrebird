# frozen_string_literal: true

module Lyrebird
  module ID
    def self.generate
      "_#{SecureRandom.uuid}"
    end
  end
end
