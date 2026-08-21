# SOMADEX V2 — species + Rezonans data layer

This stage removes battle content from hard-coded UI logic.

- `SomaskanSpecies` describes a species/form.
- `SomaskanInstance` describes one caught individual.
- `SomadexMoveData` extends godotmon's existing `AttackData` instead of replacing it.
- `ResonanceState` is a battle-native meter model; presentation is intentionally not a separate sci-fi screen.
- `.tres` files are the canonical editable content units for moves/species.

The starter resource is scaffolding for the pipeline; final canon values/names are imported only from approved SOMADEX source material.
