# Releasing Venus Media Library

1. Merge the completed, tested work to `main`.
2. Set the next version in `lib/venus_media_library/version.rb` and update the
   changelog.
3. Run `bundle exec rake app:spec`, `bin/rubocop -f simple`, `gem build`, and
   `gem check`.
4. Create an annotated version tag and GitHub Release after CI is green.
5. The trusted-publishing workflow publishes the matching version. Never put a
   RubyGems API key in the repository or GitHub secret once OIDC is configured.
6. Verify the new version on RubyGems and install it in a clean host app.

For the initial 1.0.0 release, obtain a fresh RubyGems MFA code only at the
final publication step if trusted publishing is not yet available.
