# Driving and POV control inventory

The supplied image's driving/misc.viv contains the data-driven definitions under
data/control/. The private extractor keeps the original files in ignored
staging; this page records an original summary only.

Master.def declares eight POV configurations (povcfg0.def through
povcfg7.def) and one Driving configuration (drivecfg.def). A separate
FrontEnd.def maps menu navigation, accept/cancel, start and cheat edges. The
shipping definitions are therefore part of the original control contract; the
on-foot mappings from PRD section 7 are not a complete description of vehicle
behavior.

The POV family uses both sticks for camera rotation and look, with alternate
axis actions, trigger-driven primary fire and aim, Y for camera spin, X for
reload, D-pad and face-button secondary selection, D-pad zoom, Back for
autodrive resume and LT for aim zoom. The five POV configurations with 20 mapped
action names differ from the three with 19, so a single vehicle layout cannot be
assumed across missions.

The Driving family maps left stick to steering, right stick to camera look,
RT to gas, LT to brake, B to handbrake, White/Black and left/right D-pad to
secondary selection, A to secondary fire, X to gadget fire and Y to camera
change. These are the definitions used for contextual driving labels and
acceptance, not a hard-coded substitution for the POV screens.

## Reproduction

Build the pinned engine, then run:

    python3 scripts/inventory_driving_controls.py \
      --viv build/data/<identity>/driving/misc.viv \
      --output build/data/control-defs

The script validates the BIGF directory, decodes RefPack members, extracts all
12 control definitions and writes a private manifest. The extracted definitions
remain outside the source commit. All eight POV configurations and the Driving
configuration must be exercised on device before G06 can pass.

