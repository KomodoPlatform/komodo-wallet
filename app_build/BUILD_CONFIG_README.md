# Build Configuration Guide

## TL;DR

- **Configure Coins**: Set up the coins repository details, including commit hashes, URLs, branches, and runtime update settings.

---

## `coins` Configuration

### Parameters and Explanation

- **update_commit_on_build**: A boolean flag indicating whether the commit hash should be updated on build. This ensures the coin configurations are in sync with the latest state of the repository.
- **bundled_coins_repo_commit**: Specifies the commit hash of the bundled coins repository. This ensures the coin configurations are in sync with a specific state of the repository, providing consistency and stability.

---

## Configuring and Running the Build Process

1. **Modify `build_config.json`**: Ensure the configuration file reflects your project requirements. Update commit hashes, URLs, and paths as needed.
The build steps are automatically executed as part of Flutter's build process. For any issues or further assistance, refer to the detailed comments within the build scripts or seek support from the project maintainers.
