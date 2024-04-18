# frozen_string_literal: true

require "rdap"

require "riemann/tools"

module Riemann
  module Tools
    class RDAP
      include Riemann::Tools

      opt :domains, "Domains to monitor", short: :none, type: :strings, default: []

      def tick
        opts[:domains].each do |domain|
          check_domain(domain)
        end
      end

      def check_domain(domain)
        data = ::RDAP.domain(domain)
        expiration_date = DateTime.parse(data["events"].find { |e| e["eventAction"] == "expiration" }["eventDate"])
        time_left_days = (expiration_date - DateTime.now).to_i

        description = "Domain #{domain} will expire in #{time_left_days} days"

        report_expiration(domain, time_left_days, description)
      rescue ::RDAP::NotFound
        report_expiration(domain, nil, "Domain #{domain} not found")
      end

      def report_expiration(domain, time_left_days, description)
        event = {
          service: "domain #{domain} expiration",
          metric: time_left_days,
          state: expiration_state(time_left_days),
          description: description
        }

        report event
      end

      def expiration_state(time_left_days)
        return nil unless time_left_days

        if time_left_days < 7
          "critical"
        elsif time_left_days < 30
          "warning"
        else
          "ok"
        end
      end
    end
  end
end
