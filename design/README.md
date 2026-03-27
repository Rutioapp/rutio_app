# Design Assets

`design/` stores source and reference files that must not ship in the Flutter
runtime bundle.

Rules for this project:
- Keep runtime assets under `assets/` only when the app loads them directly.
- Keep naming lowercase and `snake_case` across files and folders.
- Store branding exports, launcher icon sources, prototypes, and working files
  here instead of under `assets/`.
- When runtime images are added later, place them in focused folders such as:
  `assets/images/branding/`, `assets/images/icons/`,
  `assets/images/illustrations/`, or `assets/images/backgrounds/`.
