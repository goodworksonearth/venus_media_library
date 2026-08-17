# Releasing Venus Media Library

1. Merge the completed, tested work to `main`.
2. Set the next version in `lib/venus_media_library/version.rb` and update the
   changelog.
3. Run `bundle exec rake app:spec`, `bin/rubocop -f simple`, `gem build`, and
   `gem check`.
4. Create an annotated `v<version>` tag after CI is green. Pushing that tag
   starts `.github/workflows/release.yml`.
5. Before the first trusted release, configure the RubyGems trusted publisher
   for GitHub Actions with owner `goodworksonearth`, repository
   `venus_media_library`, workflow `release.yml`, and environment `release`.
6. The workflow publishes with short-lived OIDC credentials. Never put a
   RubyGems API key in the repository or GitHub secret once this path has been
   proven by a release.
7. Create the GitHub Release and verify the new version on RubyGems and in a
   clean host app.

For the initial 1.0.0 release, obtain a fresh RubyGems MFA code only at the
final publication step if trusted publishing is not yet available.
