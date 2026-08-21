# SOMADEX V2 battle stage

This branch introduces the first complete wild-battle loop on top of the Vela overworld foundation.

- encounter signal opens the battle UI
- overworld movement/interaction is locked during battle
- command menu: WALKA / SOMASKANY / PLECAK / UCIECZKA
- four move slots with power, accuracy and healing moves
- simple enemy turn and escape logic
- win/loss/escape closes battle and returns to the same live world
- CI captures the real battle runtime

Architecture is intentionally data-driven so the next stage can replace placeholder glyphs with final Somaskan sprites and connect party/bag/GameState without rewriting the battle state machine.
