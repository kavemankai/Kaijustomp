# Beach evolution: skin shedding and future history

Status: implementation committed. Godot runtime and Android testing still required.

## Locked gameplay contract

1. Player begins evolution with enough biomass and becomes immobile for 6 seconds initially, longer after later evolutions. No extra enemies are drawn to the process; existing threats behave normally.
2. Before any new mutation is applied, the engine snapshots the complete **old monster geometry**, including its prior visible mutations and current size. Its skin fades pale, dark cracks spread, and it shakes.
3. Normal defensive armour stays effective. Receiving 35 cumulative damage interrupts evolution and destroys all saved biomass, but previous permanent traits remain. Death still ends the run. Failure darkens and collapses the incomplete skin, leaving no completed shed.
4. Once the survival countdown completes, the entire world pauses for selection. The player sees their last four evolution choices in order alongside the new available mutations. Extra biomass expands choices, but grants only one mutation and carries forward after the pop.
5. Choosing a mutation applies a small permanent physical adaptation (and size growth if at the separate milestone). The game **remains paused** as the old skin breaks apart. The new form becomes visible underneath.
6. The final break-free reveal takes approximately 3 seconds automatically. Repeated **taps** or desktop clicks speed it up; keyboard Space does too for testing. Tapping does not shorten the dangerous part, affect rewards or create extra mutations.
7. Emergence restores full health, provides a brief vibration and camera shake, and resumes gameplay only after the reveal ends.
8. Old skins are lightweight, non-colliding, flattened pale husks with fragments. A maximum of **five** remain, for up to **40 seconds**, fading over the final seven seconds; the oldest despawns when over budget.

## Future evolution tree / web

The ordered run-local evolution_history records one dictionary per choice:
- step: the evolution number
- mutation_id: stable gameplay ID (e.g. armour, speed, jaw)
- label: human-readable mutation name
- growth_milestone: size milestone tier

The mutation draft displays the latest four entries. This stores the *sequence* needed for a future branching evolution tree or constellation/web interface, rather than merely tallying traits. Actual branching, prerequisites, persistence and a graphical tree are future features **not** implemented yet.

## Code

- scripts/beach/EvolutionShedding.gd: snapshots previous form, manages pale colour and crack marks, runs safe optional-tap reveal while world is paused, generates old skin/remnants with hard cap and fade, signals completion.
- scripts/beach/BeachDemo.gd: vulnerability countdown, failure rules, full-world pause, mutation UI/history, new form and final emergence.
- scripts/ci/test_evolution.gd: headless regression for snapshot, cracks, pause, tap reveal, history, biomass carryover, remnants and failed evolution.
- .github/workflows/beach-demo-smoke.yml: imports and launches the scene, then runs the evolution regression.

## Phone QA

- See the old appearance become pale, crack, and show the new mutation only after choice.
- Existing enemies should not gain aggro solely because evolution starts. Normal armour still protects; accumulated damage can interrupt.
- Selection and reveal must fully pause police and damage. The selection screen must fit in portrait, including when surplus biomass increases mutation options.
- Try doing nothing during reveal (auto-finishes), then repeated tapping (speeds it up).
- Complete four evolutions, inspect several different-sized shed skins; nothing collides with old skins. Check frame pacing with five sheds.
- Verify a failed evolution retains previously chosen mutations but loses all stored biomass.
- No device performance or import success has yet been confirmed for this particular revision.

The current effect is procedural placeholder art, not a final character skin rig or real fracture simulation.
