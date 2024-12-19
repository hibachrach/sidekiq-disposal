# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2024-12-19

### Changed

- **Breaking**: Replace all usages of "drop" with "discard" to align with Sidekiq terminology ([#4](https://github.com/hibachrach/sidekiq-disposal/pull/4)).
  - To upgrade:
    1. Replace all usages of `:drop` with `:discard`
    1. Replace all usages of `Sidekiq::Disposal::Client::REDIS_DROP_TARGET_SET` with `Sidekiq::Disposal::Client::REDIS_DISCARD_TARGET_SET`
    1. Replace all usages of `Sidekiq::Disposal::JobDropped` with `Sidekiq::Disposal::JobDiscarded`
    1. Replace all usages of `Sidekiq::Disposal::Client#drop_target?` with `Sidekiq::Disposal::Client#discard_target?`
    1. In Redis, execute `COPY sidekiq-disposal:drop_targets sidekiq-disposal:discard_targets`
- Eliminate round trip time when calling Redis in Sidekiq middleware ([#3](https://github.com/hibachrach/sidekiq-disposal/pull/3))

## [0.1.0] - 2024-12-13

- A new thing! The initial release of `sidekiq-disposal`. 🎉
