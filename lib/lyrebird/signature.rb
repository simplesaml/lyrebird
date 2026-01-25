# frozen_string_literal: true

module Lyrebird
  class Signature
    def initialize(element, certificate:)
      @element = element
      @certificate = certificate
    end

    def sign!
    end
  end
end
