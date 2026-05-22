# Porkrooms VR

A viral Backrooms-style VR horror game for Meta Quest 3/3S. You are trapped in procedurally generated liminal spaces — yellow wallpaper, cold fluorescent hum, and somewhere in the dark, a feral Nikita Boar hunts you.

## Status

Active development. Core systems:
- ✅ Procedural level generation (12 chambers + 11 hallways = 23 rooms)
- ✅ Dual-mode player controller (desktop WASD + VR thumbstick)
- ✅ Enemy AI — 6-state boar (idle, roam, chase, attack, jumpscare, stunned)
- ✅ Flashlight with battery drain and flicker
- ✅ Footstep system with surface detection
- ✅ Film grain / vignette / scanlines post-processing
- ✅ Inventory singleton with collectibles
- ✅ Quest immersive VR (OpenXR)
- 🔲 Room lighting visibility (black void bug in progress)

## Tech Stack

| Component | Detail |
|-----------|--------|
| Engine | Godot 4.5.stable |
| Renderer | Mobile (Vulkan) |
| Platform | Meta Quest 3 / 3S |
| XR | OpenXR via Meta OpenXR Vendors plugin |
| Assets | Blender 5.0.1 → GLB → Godot |
| Pipeline | Hermes VR DevKit |

## Development Setup

This project uses the [Hermes VR DevKit](https://github.com/buckster123/hermes-vr-devkit) — a complete Godot + Blender + Quest toolchain with MCP server integration for AI-assisted development.

See the devkit for:
- Full installation instructions
- Build and deploy scripts
- Troubleshooting matrix
- Skill contribution guidelines

### Quick Build (after devkit install)

```bash
cd ~/Projects/Porkrooms/porkrooms
# Export via Godot GUI: Project → Export → Export Project
# Sign and deploy:
~/android-sdk/build-tools/34.0.0/apksigner sign \
  --ks ~/.android/debug.keystore --ks-pass pass:android \
  --key-pass pass:android --in Porkrooms.apk --out Porkrooms.apk
adb install -r Porkrooms.apk
adb shell monkey -p com.example.porkrooms -c android.intent.category.LAUNCHER 1
```

## Contributing

See the [Hermes VR DevKit CONTRIBUTING.md](https://github.com/buckster123/hermes-vr-devkit/blob/main/CONTRIBUTING.md) for guidelines. This project follows the same conventions — focused PRs, tested on Quest hardware, and practical skill improvements over generic docs.

## Credits

- Built with the [Hermes VR DevKit](https://github.com/buckster123/hermes-vr-devkit)
- Nikita Boar concept by bonegpt
- Free/open-source assets only
