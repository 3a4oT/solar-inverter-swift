# Development

Guide for contributing to SolarCore.

## Requirements

- Swift 6.2+
- macOS 26+ or Linux
- SwiftFormat

## Setup

```bash
git clone https://github.com/3a4oT/solar-inverter-swift.git
cd solar-inverter-swift

brew install swiftformat
./Scripts/install-hooks.sh
```

## Code Style

SwiftFormat runs automatically via pre-commit hook. Configuration in `.swiftformat`.

```bash
swiftformat .          # Format all files
swiftformat . --lint   # Check only (CI mode)
```

## Testing

```bash
swift test             # Run all tests
swift test --parallel  # Parallel execution
swift test --filter StatusBuilderTests  # Specific suite
```

## Syncing Profiles

Synchronize inverter profiles from upstream [ha-solarman](https://github.com/davidrapan/ha-solarman):

```bash
./Scripts/sync-profiles.sh --help    # Show options
./Scripts/sync-profiles.sh --list    # List available profiles
./Scripts/sync-profiles.sh --all     # Sync all profiles
./Scripts/sync-profiles.sh deye_p3   # Sync specific profile
```

