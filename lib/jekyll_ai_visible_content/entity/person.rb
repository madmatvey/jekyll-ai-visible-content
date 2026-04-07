# frozen_string_literal: true

module JekyllAiVisibleContent
  module Entity
    class Person
      attr_reader :config

      def initialize(config)
        @config = config
      end

      def to_hash
        entity = config.entity
        data = {
          "@type" => "Person",
          "@id" => config.entity_id,
          "name" => entity["name"],
          "url" => config.site_url
        }

        append_alternate_names(data, entity)
        append_image(data, entity)
        append_simple_fields(data, entity)
        append_address(data, entity)
        append_knows_about(data, entity)
        append_same_as(data, entity)
        append_works_for(data, entity)
        append_occupation(data, entity)

        data.compact
      end

      private

      def append_alternate_names(data, entity)
        names = entity["alternate_names"]
        data["alternateName"] = names if names&.any?
      end

      def append_image(data, entity)
        return unless entity["image"]

        url = absolute_url(entity["image"])
        data["image"] = {
          "@type" => "ImageObject",
          "url" => url
        }
      end

      def append_simple_fields(data, entity)
        data["jobTitle"] = entity["job_title"] if entity["job_title"]
        data["description"] = entity["description"]&.strip if entity["description"]
        data["email"] = entity["email"] if entity["email"]
      end

      def append_address(data, entity)
        loc = entity["location"]
        return unless loc && (loc["locality"] || loc["country"])

        data["address"] = {
          "@type" => "PostalAddress",
          "addressLocality" => loc["locality"],
          "addressCountry" => loc["country"]
        }.compact
      end

      def append_knows_about(data, entity)
        items = entity["knows_about"]
        data["knowsAbout"] = items if items&.any?
      end

      def append_same_as(data, entity)
        links = entity["same_as"]
        data["sameAs"] = links if links&.any?
      end

      def append_works_for(data, entity)
        wf = entity["works_for"]
        return unless wf

        data["worksFor"] = {
          "@type" => wf["type"] || "Organization",
          "name" => wf["name"]
        }.compact
      end

      def append_occupation(data, entity)
        occ = entity["occupation"]
        return unless occ

        occupation = {
          "@type" => "Occupation",
          "name" => occ["name"]
        }

        if occ["location_country"]
          occupation["occupationLocation"] = {
            "@type" => "Country",
            "name" => occ["location_country"]
          }
        end

        occupation["skills"] = occ["skills"] if occ["skills"]
        data["hasOccupation"] = occupation.compact
      end

      def absolute_url(path)
        return path if path&.start_with?("http")

        "#{config.site_url}#{path}"
      end
    end
  end
end
