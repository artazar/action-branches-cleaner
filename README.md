# Branches Cleaner Github Action <a href="https://devhunt.org/tool/branches-cleaner" alt="upvote in devhunt">Upvote us in Devhunt\_</a>

<p align="center">
    <img src="assets/branche_cleaner.svg" alt="github action icon" width="250px" height="250px">
</p>

## Why Clean Up Your Branches?

Keeping your repository clean is crucial for team productivity and project maintainability:

- **🔍 Difficult Navigation**: Too many branches make it hard to find active work
- **😵 Confusing Pull Requests**: Obsolete branches create noise in PR lists
- **⏱️ Slow Performance**: Repositories with hundreds of stale branches can become sluggish
- **🤔 Team Confusion**: Developers may accidentally work on outdated branches
- **📊 Poor Repository Health**: Cluttered branch lists reflect poorly on project organization

## What This Action Does

This GitHub Action automatically cleans up branches in your repository by removing:

✅ **Closed PR branches without merges** - Feature branches that were rejected or abandoned  
✅ **Already merged branches** - Branches that have been successfully integrated  
✅ **Inactive branches** - Branches with no commits for a specified period (configurable)  
✅ **Smart protection** - Never touches your important base branches (main, develop, etc.)

## Key Benefits

- 🧹 **Cleaner repository** that's easier to navigate
- ⚡ **Better performance** and faster operations
- 👥 **Less confusion** for your development team
- 🔄 **Full automation** - runs on schedule without manual intervention
- 🛡️ **Safe operation** - protects your important branches
- 📈 **Better project health** - maintains a professional, organized repository

You can specify the base branches or protected branches that should not be deleted, and configure how many days of inactivity before a branch is considered stale.

<a href="https://www.buymeacoffee.com/mmoreno" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me a Coffee" style="height: auto !important;width: 100px !important;" ></a>

## Inputs

### `base_branches`

**_Required_**. Comma-separated string of the base branches that you want to keep. For example: `main,develop`.

### `token`

**_Required_**. Token to authenticate with the GitHub API.

### `days_old_threshold`

**_Optional_**. Number of days of inactivity to remove inactive branches. Default is `7`.

## Usage

This GitHub Action can be triggered by different events offered by GitHub, depending on the needs of each team or individual. In the following example, a schedule trigger is used to run the action every day at midnight:

```yaml
name: Branches Cleaner

on:
  schedule:
    - cron: "0 0 * * *"

jobs:
  cleanup-branches:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v2
      - name: GitHub Branch Cleaner
        uses: mmorenoregalado/action-branches-cleaner@v2.0.1
        with:
          base_branches: develop,master
          token: ${{ secrets.GITHUB_TOKEN }}
          days_old_threshold: 7
```

Refer to the [official GitHub documentation](https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows) for more information on the different events that can be used to
trigger GitHub Actions.

## Troubleshooting

If you encounter an error with exit code 127 when running this action, it may be due to restrictions on workflow runs in your repository settings. To resolve this issue, please check if the action is allowed to run:

1. Go to your repository's settings.
2. Navigate to the "Actions" tab.
3. Under "General" settings, look for "Workflow permissions".
4. Make sure that the Read and write permissions option is selected, which allows workflows to have read and write permissions in the repository for all scopes.

## Usage the latest version

To use the latest version:

1. Click on the following link http://bit.ly/3zgLxHf. This will redirect you to the official GitHub Action Page
2. Then click on `Use latest version`:

   <img src="assets/cleaner_latest.png" style="width:250px" alt="Click latest version"/>

3. Finally replace the text in the GitHub Action YAML file in your .git/workflows/ folder.

   <img src="assets/cleaner_dialog.png" style="width:350px" alt="Copy content"/>

With that you will have the latest version of Branches Cleaner installed.

## Testing

This action includes comprehensive testing to ensure it works correctly. The testing suite includes:

- **Unit Tests**: Using Bats to test individual functions
- **Integration Tests**: Using Docker to simulate a GitHub Actions environment
- **Functional Tests**: Using real GitHub Actions workflows

To run the tests locally:

```bash
# Unit tests
bats test/bats

# Integration tests
cd test/docker
docker-compose up --build

# Specific test for inactive branches feature
./test/inactive_branches_test.sh
```

For more details about the testing setup, see the [test documentation](test/README.md).

## Contributing

This action is open to contributions. If you find any issues or bugs, feel free to open an issue or pull request.

When contributing, please:

1. Add tests for new features or bug fixes
2. Ensure all tests pass before submitting a pull request
3. Update documentation as needed

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Development

To set up the development environment:

```bash
# Clone the repository
git clone https://github.com/mmorenoregalado/action-branches-cleaner.git
cd action-branches-cleaner
```

### Testing Options

#### Running tests with Docker (recommended)

You can run all tests using Docker without needing to install any dependencies locally:

```bash
# Run all tests using Docker
cd test/docker
docker-compose up --build
```

This approach provides a clean, isolated environment that matches the GitHub Actions runtime.

#### Running specific test scenarios

You can run specific tests using docker-compose with these simplified commands. First, navigate to the docker directory:

```bash
# Navigate to the docker directory
cd test/docker
```

Then run your tests:

```bash
# Run a specific Bats test file
docker-compose run test bats /github/workspace/test/bats/github_test.bats

# Run the inactive branches test
docker-compose run test bats /github/workspace/test/bats/inactive_branches_test.bats

# Run all tests with a pattern
docker-compose run test bats "/github/workspace/test/bats/*_test.bats"

# Run a specific shell script test
docker-compose run test /github/workspace/test/inactive_branches_test.sh
```

These commands work when executed from the test/docker directory where docker-compose.yml is located. This approach makes testing more straightforward while still using the same Docker environment that matches GitHub Actions.
