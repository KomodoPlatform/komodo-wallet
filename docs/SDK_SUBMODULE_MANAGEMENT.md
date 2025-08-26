# SDK Submodule Management

This document provides guidance on working with the Komodo DeFi SDK Flutter submodule in the Komodo Wallet project.

## Overview

The Komodo Wallet project uses the komodo-defi-sdk-flutter repository as a git submodule located in the `sdk/` directory. This allows us to:

- Track specific SDK versions
- Test changes locally before they're published
- Create hotfixes for urgent SDK issues
- Maintain dependency consistency across development environments

## Initial Setup

After cloning the repository, you must initialize the submodule:

```bash
git submodule update --init --recursive
```

This will clone the SDK repository into the `sdk/` folder and checkout the tracked commit on the `dev` branch.

## Working with the SDK Submodule

### Updating to Latest SDK Changes

To update the submodule to the latest changes from the upstream `dev` branch:

```bash
cd sdk
git fetch origin
git checkout dev
git pull origin dev
cd ..
git add sdk
git commit -m "Update SDK submodule to latest dev"
```

### Making SDK Changes (Hotfix Workflow)

When you need to make changes to the SDK:

1. **Create a hotfix branch in the SDK submodule:**

   ```bash
   cd sdk
   git checkout dev
   git pull origin dev
   git checkout -b hotfix/your-fix-name
   ```

2. **Make your changes and test locally:**

   ```bash
   # Make your code changes...
   git add .
   git commit -m "Hotfix: describe your fix"
   ```

3. **Test the changes in the wallet:**

   ```bash
   cd ..  # Back to wallet root
   flutter clean
   flutter pub get
   flutter test  # Run your tests
   flutter build web  # Ensure builds work
   ```

4. **Push the hotfix branch:**

   ```bash
   cd sdk
   git push -u origin hotfix/your-fix-name
   ```

5. **Create a PR in the SDK repository** from `hotfix/your-fix-name` to `dev`

6. **After the hotfix is merged**, update the wallet to track the new commit:

   ```bash
   cd sdk
   git checkout dev
   git pull origin dev
   cd ..
   git add sdk
   git commit -m "Update SDK submodule to include hotfix"
   ```

### Switching SDK Branches

To temporarily switch to a different SDK branch for testing:

```bash
cd sdk
git fetch origin
git checkout feature/some-feature-branch
cd ..
flutter clean
flutter pub get
```

**Note:** Remember to commit the submodule state change if you want to track this branch:

```bash
git add sdk
git commit -m "Switch SDK to feature/some-feature-branch for testing"
```

## Best Practices

### Do's ✅

- **Always commit submodule changes** in the wallet repository when updating the SDK
- **Test thoroughly** before pushing submodule updates
- **Use descriptive commit messages** when updating the submodule (e.g., "Update SDK to v2.4.0 with new trading features")
- **Keep the submodule on `dev` branch** for production builds
- **Use hotfix branches** for urgent SDK fixes
- **Document breaking changes** when updating the SDK

### Don'ts ❌

- **Don't work in detached HEAD state** - always checkout a branch in the submodule
- **Don't push wallet changes** that reference unpublished SDK commits (others won't be able to build)
- **Don't bypass the submodule** - avoid direct modifications to `sdk/` folder
- **Don't ignore dependency overrides** - ensure `pubspec.yaml` overrides are maintained

### Dependency Management

The wallet project uses dependency overrides to ensure all packages use the local SDK versions:

```yaml
dependency_overrides:
  komodo_defi_sdk:
    path: sdk/packages/komodo_defi_sdk
  komodo_defi_types:
    path: sdk/packages/komodo_defi_types
  # ... other SDK packages
```

These overrides ensure that even if SDK packages internally reference hosted versions, the wallet will use the local path versions.

## Troubleshooting

### Submodule Not Initialized

If you see errors about missing SDK packages:

```bash
git submodule update --init --recursive
flutter clean
flutter pub get
```

### Dependency Resolution Conflicts

If you get dependency resolution conflicts after updating the SDK:

1. Ensure dependency overrides are present in `pubspec.yaml`
2. Clean and reinstall dependencies:

   ```bash
   flutter clean
   flutter pub get
   ```

3. For nested packages, ensure overrides are also in their `pubspec.yaml` files

### Detached HEAD State

If the submodule is in detached HEAD state:

```bash
cd sdk
git checkout dev  # or appropriate branch
git pull origin dev
cd ..
git add sdk
git commit -m "Fix SDK submodule branch tracking"
```

### Build Failures After SDK Update

1. Check if there are breaking changes in the SDK
2. Update import statements if packages were restructured
3. Review SDK changelog/release notes
4. Consider rolling back to previous working commit temporarily

## CI/CD Considerations

GitHub Actions and other CI systems need to initialize submodules. The workflows have been updated to include:

```yaml
- uses: actions/checkout@v4
  with:
    submodules: recursive
```

This ensures the CI environment has access to the SDK code during builds and tests.

## Related Documentation

- [PROJECT_SETUP.md](PROJECT_SETUP.md) - Initial project setup including submodule initialization
- [CLONE_REPOSITORY.md](CLONE_REPOSITORY.md) - Repository cloning instructions
- [SDK_DEPENDENCY_MANAGEMENT.md](SDK_DEPENDENCY_MANAGEMENT.md) - General dependency management guidelines
