#!/usr/bin/env bats

load '../test_helper.bash'

# Setup for all tests
setup() {
  # Configure mocks to avoid real calls
  curl() {
    case "$*" in
      *"pulls?state=closed"*)
        echo '[{"head": {"ref": "feature/test1"}}, {"head": {"ref": "feature/test2"}, "merged_at": "2023-01-01"}]'
        ;;
      *"branches?protected=false"*)
        echo '[{"name": "feature/test1"}, {"name": "feature/test2"}, {"name": "main"}]'
        ;;
      *"branches/feature/test1"*)
        echo '{"commit": {"commit": {"committer": {"date": "2020-01-01T00:00:00Z"}}}}'
        ;;
      *"branches/feature/test2"*)
        echo '{"commit": {"commit": {"committer": {"date": "2023-01-10T00:00:00Z"}}}}'
        ;;
      *"DELETE"*)
        echo "DELETE operation performed on ${*##*/heads/}"
        ;;
      *)
        return 0
        ;;
    esac
  }
  
  # Mock date to have consistent dates
  date() {
    if [[ "$*" == *"--date=\"7 day ago\""* || "$*" == *"--date=7 day ago"* ]]; then
      echo "2023-01-05T00:00:00Z"
    elif [[ "$*" == *"-d \"2020-01-01T00:00:00Z\""* || "$*" == *"-d 2020-01-01T00:00:00Z"* ]]; then
      echo "1577836800"
    elif [[ "$*" == *"-d \"2023-01-05T00:00:00Z\""* || "$*" == *"-d 2023-01-05T00:00:00Z"* ]]; then
      echo "1672876800"
    elif [[ "$*" == *"-d \"2023-01-10T00:00:00Z\""* || "$*" == *"-d 2023-01-10T00:00:00Z"* ]]; then
      echo "1673308800"
    else
      echo "2023-01-12T00:00:00Z"
    fi
  }
  
  # Load all necessary scripts
  source "${BATS_TEST_DIRNAME}/../../src/github.sh"
  source "${BATS_TEST_DIRNAME}/../../src/cleanup.sh"
  source "${BATS_TEST_DIRNAME}/../../src/main.sh"
  
  # Required environment variables
  export GITHUB_TOKEN="fake-token"
  export GITHUB_REPOSITORY="test-user/test-repo"
}

@test "Complete branch cleanup flow" {
  # Execute the main function with test parameters
  run main "main,develop" "7" "fake-token"
  
  # Verifications
  [ "$status" -eq 0 ]
  
  # Check that merged branches were detected and deleted
  [[ "$output" == *"Deleting merged branch: feature/test2"* ]]
  
  # Check that non-merged branches were detected and deleted
  [[ "$output" == *"Deleting not merged branch: feature/test1"* ]]
  
  # Check that inactive branches were detected and deleted (feature/old is the inactive one)
  [[ "$output" == *"Deleting inactive branch: feature/old"* ]]
  
  # Check that base branches were not touched
  [[ "$output" != *"Deleting"*"main"* ]]
}

@test "Flow with protected base branches" {
  # First, show current base branches for debugging
  echo "BASE_BRANCHES before: ${BASE_BRANCHES[*]}"
  
  # Configure base branches explicitly
  BASE_BRANCHES=("main" "develop" "feature/test2")
  export BASE_BRANCHES
  
  # Verify they were configured correctly
  echo "BASE_BRANCHES after: ${BASE_BRANCHES[*]}"
  
  # Execute the main function
  # Note: Although we pass "main,develop,feature/test2", let's ensure BASE_BRANCHES is correctly configured
  run main "main,develop,feature/test2" "7" "fake-token"
  
  # Show all output for debugging
  echo "Output: $output"
  
  # Verifications
  [ "$status" -eq 0 ]
  
  # Check that feature/test2 was NOT deleted (we modified this expectation)
  [[ ! "$output" == *"Deleting merged branch: feature/test2"* ]]
  
  # Check that feature/test1 WAS deleted
  [[ "$output" == *"Deleting not merged branch: feature/test1"* ]]
}

@test "Custom day threshold" {
  # Use a 30-day threshold
  run main "main" "30" "fake-token"
  
  # Verifications
  [ "$status" -eq 0 ]
  
  # Merged and non-merged branches are still processed
  [[ "$output" == *"Deleting merged branch: feature/test2"* ]]
  [[ "$output" == *"Deleting not merged branch: feature/test1"* ]]
  
  # With a 30-day threshold, only feature/old should be inactive
  [[ "$output" == *"Deleting inactive branch: feature/old"* ]]
} 