module VenusMediaLibrary
  # Resolves the file types a picker field accepts and matches content types
  # against them, so the same rule drives the browser's native <input accept>,
  # the greying-out of non-matching library assets, and the server-side upload
  # check. A token may be:
  #   - an exact mime type   ("image/png")
  #   - a type wildcard      ("image/*")
  #   - a file extension     (".png")
  # Extensions are mapped to a mime type via Marcel so server-side matching stays
  # consistent with what the browser lets a user pick from disk.
  #
  # This is a plain value object (not Active Record); it lives under app/models
  # only so Zeitwerk autoloads it alongside the engine's other domain types.
  class AcceptedTypes
    def self.parse(raw)
      tokens = Array(raw).flat_map { |value| value.to_s.split(",") }.map(&:strip).reject(&:blank?)
      new(tokens)
    end

    attr_reader :tokens

    def initialize(tokens)
      @tokens = Array(tokens).uniq
    end

    def any?
      @tokens.any?
    end

    # The value handed to a native <input accept="..."> — the raw tokens joined.
    def to_input_accept
      @tokens.join(",")
    end

    # True when `content_type` satisfies at least one accepted token.
    def matches?(content_type)
      return false if content_type.blank?

      @tokens.any? { |token| token_matches?(token, content_type) }
    end

    private

    def token_matches?(token, content_type)
      if token.start_with?(".")
        extension_matches?(token, content_type)
      elsif token.end_with?("/*")
        content_type.start_with?(token.delete_suffix("*"))
      else
        token == content_type
      end
    end

    def extension_matches?(token, content_type)
      extension = token.delete_prefix(".").downcase
      Marcel::MimeType.for(name: "file.#{extension}") == content_type
    end
  end
end
