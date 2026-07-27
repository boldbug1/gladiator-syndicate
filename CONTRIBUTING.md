# Contributing

## Scene Ownership

Each scene has a designated owner to avoid merge conflicts:

| Scene | Owner |
|-------|-------|
| `scenes/player.tscn` + `player.gd` | |
| `scenes/platform.tscn` + `platform.gd` | |
| `scenes/enemy.tscn` + `enemy.gd` | |
| `scenes/ui.tscn` + `ui.gd` | |
| `scenes/main.tscn` | Shared (coordinate changes) |

Fill in your name next to the scene you own.

## Workflow

1. Always `git pull` before starting work
2. Create a branch for your feature: `git checkout -b feature/your-feature`
3. Only edit files you own
4. Commit often with clear messages
5. Open a PR and have someone review before merging to `main`

## Scripts

Create your script as a `.gd` file alongside your scene (e.g. `player.gd` for `player.tscn`). Attach it in the Godot editor.

## Avoid

- Don't edit someone else's scene file without asking
- Don't push directly to `main` — use branches + PRs
- Don't commit the `.godot/` folder (it's in `.gitignore`)
