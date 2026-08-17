# Contributing

## Local setup

```bash
bundle install
RAILS_ENV=test bundle exec rake app:db:migrate
bundle exec rake app:spec
bin/rubocop -f simple
```

The dummy host application uses SQLite and Active Storage's Disk service. It is
intended to exercise the engine as a mounted host would.

## Change expectations

- Keep public behavior documented in `README.md` and recorded in `CHANGELOG.md`.
- Add a focused regression spec for every behavior change.
- Run the full request/model/helper suite and RuboCop before opening a PR.
- Do not add credentials, generated gems, storage files, or local databases to Git.

## Pull requests

Use one focused branch and PR per task. Explain the user impact, any migration
or host configuration changes, and the validation run. Maintainers merge only
green, reviewable changes.
