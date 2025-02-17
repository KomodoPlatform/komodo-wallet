# Build Config

## Overview

Coin configs and asset files are automatically downloaded as part of the flutter build pipeline, based on the settings configured in [build_config.json](/app_build/build_config.json).

There are is one section of note in [build_config.json](/app_build/build_config.json),

- `coins` contains the configuration for fetching the coin assets, including where to download the files to and where to download the files from.

The config is read by the build step for every invocation of `flutter run` or `flutter build`, so no further actions are required to update the coin assets or API binaries.

NOTE: The build step will fail on the first run if the coin assets are not present in the specified folders. Run the same command again and the build should succeed.

## Coins

The build step will check [build_config.json](/app_build/build_config.json) for the [coins](https://github.com/KomodoPlatform/coins) repository GitHub API URL, branch and commit hash, and it will then download the mapped files and folders from the repository to the specified local files and folders.

By default, the build step will

- Download the coin assets from the latest commit in the branch of the coins repository specified in `build_config.json`
- Skip assets if the file already exists.

### Configuration

In [build_config.json](/app_build/build_config.json) update `bundled_coins_repo_commit` and `coins_repo_branch` to the latest commit hash in the desired branch name. Example:

```json
    "coins": {
        "bundled_coins_repo_commit": "f956070bc4c33723f753ed6ecaf2dc32a6f44972",
        "coins_repo_branch": "master",
        ...
    }
```

To update or add to the files and folders synced from the [coins](https://github.com/KomodoPlatform/coins), modify the `mapped_files` and `mapped_folders` sections respectively. Example:

NOTE: The coins repository path on the right should be relative to the root of the coins repository. The local path, on the left, should be relative to the root of this repository.

```json
{
    "coins": {
        ...,
        "mapped_files": {
            "assets/config/coins_config.json": "utils/coins_config.json",
            "assets/config/coins.json": "coins"
        },
        "mapped_folders": {
            "assets/coin_icons/png/": "icons"
        }
    }
}
```
