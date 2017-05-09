# frozen_string_literal: true

require_relative '../filter'

require 'set'

module OctocatalogDiff
  module CatalogDiff
    class Filter
      # Filter out changes between an array of a single value and a single value
      # E.g. Treat Service[httpd] and ["Service[httpd]"] as the same
      class ArraySingleValue < OctocatalogDiff::CatalogDiff::Filter
        KEEP_ATTRIBUTES = (Set.new %w(ensure backup force provider)).freeze

        # Constructor: Since this filter requires knowledge of the entire array of diffs,
        # override the inherited method to store those diffs in an instance variable.
        # @param diffs [Array<OctocatalogDiff::API::V1::Diff>] Difference array
        # @param _logger [?] Ignored
        def initialize(diffs, _logger = nil)
          @diffs = diffs
          @results = nil
        end

        # Public: If a file has ensure => absent, there are certain parameters that don't
        # matter anymore. Filter out any such parameters from the result array.
        # Return true if the difference is in a resource where `ensure => absent` has been
        # declared. Return false if they this is not the case.
        #
        # @param diff [OctocatalogDiff::API::V1::Diff] Difference
        # @param _options [Hash] Additional options (there are none for this filter)
        # @return [Boolean] true if this difference is a YAML file with identical objects, false otherwise
        def filtered?(diff, _options = {})
          build_results if @results.nil?
          @results.include?(diff)
        end

        private

        # Private: The first time `.filtered?` is called, build up the cache of results.
        # Returns nothing, but populates @results.
        def build_results
          # Which files can we ignore?
          @files_to_ignore = Set.new
          @diffs.each do |diff|
            if diff.new_value.is_a?(Array) && diff.new_value.length == 1
              @files_to_ignore.add diff.title if diff.new_value[0] == diff.old_value
            end
          end

          # Based on that, which diffs can we ignore?
          @results = Set.new @diffs.reject { |diff| keep_diff?(diff) }
        end

        # Private: Determine whether to keep a particular diff.
        # @param diff [OctocatalogDiff::API::V1::Diff] Difference under consideration
        # @return [Boolean] true = keep, false = discard
        def keep_diff?(diff)
          return false if @files_to_ignore.include?(diff.title)
          true
        end
      end
    end
  end
end
