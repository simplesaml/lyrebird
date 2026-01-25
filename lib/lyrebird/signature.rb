# frozen_string_literal: true

module Lyrebird
  class Signature
    def initialize(element, certificate:)
      @element = element
      @certificate = certificate
      @element_id = @element.attributes["ID"]
    end

    def sign!
    end

    def reference
      REXML::Element.new("ds:Reference").tap do |ref|
        ref.add_attribute("URI", "##{@element_id}")
        ref.add_element(transforms)
      end
    end

    private

    def transforms
      REXML::Element.new("ds:Transforms").tap do |t|
        enveloped = t.add_element("ds:Transform")
        enveloped.add_attribute("Algorithm", ENVELOPED_SIG)
        c14n = t.add_element("ds:Transform")
        c14n.add_attribute("Algorithm", EXC_C14N)
      end
    end
  end
end
