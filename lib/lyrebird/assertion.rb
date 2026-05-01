# frozen_string_literal: true

module Lyrebird
  class Assertion
    def initialize(
      issuer: DEFAULTS.issuer,
      name_id: DEFAULTS.name_id,
      name_id_format: DEFAULTS.name_id_format,
      recipient: DEFAULTS.recipient,
      in_response_to: DEFAULTS.in_response_to,
      not_before: nil,
      valid_for: DEFAULTS.valid_for,
      audience: DEFAULTS.audience,
      authn_context: DEFAULTS.authn_context,
      attributes: DEFAULTS.attributes
    )
      @issue_instant = Time.now.utc
      @issuer = issuer
      @name_id = name_id
      @name_id_format = name_id_format
      @recipient = recipient
      @in_response_to = in_response_to
      @not_before = not_before || @issue_instant
      @not_on_or_after = @issue_instant + valid_for
      @audience = audience
      @authn_context = authn_context
      @attributes = attributes
    end

    def document
      @document ||= Nokogiri::XML::Document.new.tap do |doc|
        doc.root = root(doc)
      end
    end

    private

    def root(doc)
      doc.create_element("Assertion").tap do |a|
        ns = a.add_namespace_definition("saml", SAML_ASSERTION_NS)

        a.namespace = ns
        a["ID"] = ID.generate
        a["Version"] = "2.0"
        a["IssueInstant"] = @issue_instant.iso8601

        a.add_child(doc.create_element("Issuer")).tap do |i|
          i.namespace = ns
          i.content = @issuer
        end

        a.add_child(subject(doc, ns))
        a.add_child(conditions(doc, ns))
        a.add_child(authn_statement(doc, ns))
        a.add_child(attribute_statement(doc, ns)) if @attributes.any?
      end
    end

    def subject(doc, ns)
      doc.create_element("Subject").tap do |s|
        s.namespace = ns

        s.add_child(doc.create_element("NameID")).tap do |nid|
          nid.namespace = ns
          nid["Format"] = @name_id_format
          nid.content = @name_id
        end

        s.add_child(subject_confirmation(doc, ns))
      end
    end

    def subject_confirmation(doc, ns)
      doc.create_element("SubjectConfirmation").tap do |sc|
        sc.namespace = ns
        sc["Method"] = CM_BEARER

        sc.add_child(doc.create_element("SubjectConfirmationData")).tap do |d|
          d.namespace = ns
          d["NotOnOrAfter"] = @not_on_or_after.iso8601
          d["Recipient"] = @recipient
          d["InResponseTo"] = @in_response_to if @in_response_to
        end
      end
    end

    def conditions(doc, ns)
      doc.create_element("Conditions").tap do |c|
        c.namespace = ns
        c["NotBefore"] = @not_before.iso8601
        c["NotOnOrAfter"] = @not_on_or_after.iso8601

        c.add_child(doc.create_element("AudienceRestriction")).tap do |ar|
          ar.namespace = ns
          ar.add_child(doc.create_element("Audience")).tap do |a|
            a.namespace = ns
            a.content = @audience
          end
        end
      end
    end

    def authn_statement(doc, ns)
      doc.create_element("AuthnStatement").tap do |as|
        as.namespace = ns
        as["AuthnInstant"] = @issue_instant.iso8601
        as["SessionIndex"] = ID.generate

        as.add_child(doc.create_element("AuthnContext")).tap do |ac|
          ac.namespace = ns
          ac.add_child(doc.create_element("AuthnContextClassRef")).tap do |cr|
            cr.namespace = ns
            cr.content = @authn_context
          end
        end
      end
    end

    def attribute_statement(doc, ns)
      doc.create_element("AttributeStatement").tap do |as|
        as.namespace = ns

        @attributes.each do |name, values|
          as.add_child(doc.create_element("Attribute")).tap do |a|
            a.namespace = ns
            a["Name"] = name
            a["NameFormat"] = ATTR_NAME_FORMAT

            Array(values).each do |value|
              a.add_child(doc.create_element("AttributeValue")).tap do |av|
                av.namespace = ns
                av.content = value
              end
            end
          end
        end
      end
    end
  end
end
