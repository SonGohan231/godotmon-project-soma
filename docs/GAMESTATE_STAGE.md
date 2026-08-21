# SOMADEX V2 — persistent GameState

This branch ports the already-tested persistence foundation onto the current accepted handheld main.

It keeps the accepted D-pad/A/Z/START presentation untouched and adds only data/state foundations:
- trainer level, XP and five progression paths,
- party up to six Somaskans plus storage,
- shared bag,
- quest/world flags,
- world position/facing,
- capture to party/storage,
- versioned JSON save/load.

The dedicated CI smoke test validates save/load roundtrip and progression without changing visual presentation.
