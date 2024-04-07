# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Known unresolved issues
* Logging is very chatty.
* Caching is hardwired, everything and doesn't update. Currently only `Metalove.purge/0` as stopgap measure
* API is preliminary and missing any sort of meaningful error handling.
* ID3 tag parsing is best effort and just based on the specs and a few sample files. Needs hardening.

## Unreleased

- replace HTTPoison with Req

## [0.4.0] - 2024-04-05

- update dependencies
- code cleanup (adjustments to modern Elixir/Erlang)

## [0.3.0] - 2019-07-05

### Added
- improved `ml.chapters`: safe cover image, add option to output `mp4chaps` and `json` as well.

### Changed
- depending on `chapters ~> 1.0` for chapter generation.
- use `chapters` functions to parse and format normal playtime.
- `ml.chapters` now writes to a tmp location and reports it if no output path is given. Previously the files were written next to the source file, and failed when a URL was given.

### Fixed
- trim whitespace around URLs in ID3 parsing, properly recognise an empty string as `nil`.

## [0.2.3] - 2019-06-21

### Added
- add `.iex.exs` file with convenience aliases and fancy prompt for quicker turnaround.

### Fixed
- do not crash due to debug string generation when encountering flags in ID3 headers (e.g. `:unsync`).
- properly handle unsynchronization in ID3 tags.
- properly handle utf16 strings in ID3 tag text content. (incorrectly accidentially split utf16 characters if two zero bytes where encountered)
- translate `image/jpg` to `image/jpeg` so mimerl properly returns an extension.
- make `ml.chapter` task not crash on empty chapters.

### Changed
- update dependencies.

## [0.2.2] - 2019-05-30

### Fixed
- properly recognize `application/x-rss+xml` as allowed feed content-type.

## [0.2.1] - 2019-02-27

### Added
- `Metalove.version/0` to use in `Fetcher` headers and users of the library.

### Fixed
- remove use MixProject.project() so the library can be used by other projects.
- make functions properly private and clean up the generated docs.
- casing of readme in docs so the hexdoc link works.

## [0.2.0] - 2019-02-26

### Added
- Core functionality, find, parse and ingest podcasts from website URLs
  and feed URLs
- `ml.chapter` mix task to parse ID3 headers from mp3 files, extract the chapter information and images.
- `ml.podcast` mix task to discover and parse a feed to display a nice human readable terminal version.

[Unreleased]: https://github.com/podlove/metalove/compare/v0.3.0...HEAD
[0.3.0]: https://github.com/podlove/metalove/compare/v0.2.3...v0.3.0
[0.2.3]: https://github.com/podlove/metalove/compare/v0.2.2...v0.2.3
[0.2.2]: https://github.com/podlove/metalove/compare/v0.2.1...v0.2.2
[0.2.1]: https://github.com/podlove/metalove/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/podlove/metalove/releases/tag/v0.2.0
