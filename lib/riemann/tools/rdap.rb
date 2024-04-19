# frozen_string_literal: true

require "public_suffix"
require "rdap"

require "riemann/tools"

module Riemann
  module Tools
    class Rdap
      include Riemann::Tools

      opt :domains, "Domains to monitor", short: :none, type: :strings, default: []
      opt :expiration_warning_days, "Number of days before expiration to warn", short: :none, default: 30
      opt :expiration_critical_days, "Number of days before expiration to alert", short: :none, default: 7

      def public_suffix_domains
        @public_suffix_domains ||= opts[:domains].map { |d| PublicSuffix.domain(d) }.uniq
      end

      def tick
        public_suffix_domains.each do |domain|
          check_domain(domain)
        end
      end

      def check_domain(domain)
        data = RDAP.domain(domain)
        expiration_date = DateTime.parse(data["events"].find { |e| e["eventAction"] == "expiration" }["eventDate"])
        time_left_days = (expiration_date - DateTime.now).to_i

        description = "Domain #{domain} will expire in #{time_left_days} days"

        report_expiration(domain, time_left_days, description)
      rescue RDAP::NotFound
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

        if time_left_days < opts[:expiration_critical_days]
          "critical"
        elsif time_left_days < opts[:expiration_warning_days]
          "warning"
        else
          "ok"
        end
      end
    end
  end
end
