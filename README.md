# NightPad

NightPad is a native iPhone and iPad port of the original Xbox release of
*007: Nightfire*, built from the reconstructed
[nightfire-cxbx](https://github.com/NightfireResearch/nightfire-cxbx) engine.
The app uses the owner's extracted game data. Neither the disc image nor saved
games are part of this repository.

The implementation instructions are in
[docs/NIGHTPAD_GOAL_LOOP.md](docs/NIGHTPAD_GOAL_LOOP.md), with the product
requirements in [docs/NIGHTPAD_PRD.md](docs/NIGHTPAD_PRD.md). Current verified
progress and the next unresolved gate are in [docs/STATUS.md](docs/STATUS.md).

The exact public source revisions and local build commands are recorded in
[config/dependencies.lock.json](config/dependencies.lock.json). To rebuild a
dependency checkout, run `scripts/bootstrap_dependencies.sh`. To prepare the
owner-supplied image, run `scripts/prepare_game_data.py --iso <path>`; the
script lists and validates the image before extracting it into ignored staging.

Do not commit retail images, extracted game data, saves, device captures or
signing material. The upstream engine has no reviewed first-party license file;
public distribution remains a separate decision.

