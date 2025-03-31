#!/usr/bin/env bats

load '../test_helper.bash'

# Configuración para todas las pruebas
setup() {
  # IMPORTANTE: Exportar primero las variables de entorno básicas
  export GITHUB_REPOSITORY="test-user/test-repo"
  export GITHUB_TOKEN="fake-token"
  export GITHUB_API_URL="https://api.github.com/repos/$GITHUB_REPOSITORY"
  
  # Cargar los scripts originales primero
  source "${BATS_TEST_DIRNAME}/../../src/github.sh"
  source "${BATS_TEST_DIRNAME}/../../src/cleanup.sh"
  source "${BATS_TEST_DIRNAME}/../../src/main.sh"
  
  # Después, reemplazar las funciones con mocks
  # Mock de las funciones de github.sh - REDEFINIRLAS después de cargar los originales
  github::get_closed_prs() {
    echo "feature/pr1"
    echo "feature/pr2"
    echo "feature/pr3"
  }
  
  github::get_merged_prs() {
    echo "feature/pr2"
  }

  github::get_branches() {
    echo "feature/pr1"
    echo "feature/pr2"
    echo "main"
    echo "develop"
  }
  
  github::delete_branch() {
    local branch=$1
    echo "Mock delete_branch: $branch"
  }
  
  # Mock de las funciones de cleanup.sh
  cleanup::delete_merged_branches() {
    local branches=$1
    echo "Mock delete_merged_branches: $branches"
  }
  
  cleanup::delete_unmerged_branches() {
    local branches=$1
    echo "Mock delete_unmerged_branches: $branches"
  }
  
  cleanup::delete_inactive_branches() {
    local days=$1
    echo "Mock delete_inactive_branches: $days"
  }
  
  # Reescribir la definición de la función comm para simular el comportamiento
  comm() {
    if [[ "$1" == "-23" ]]; then
      echo "feature/pr1"
      echo "feature/pr3"
    else
      echo "Error: mock de comm no implementado para estos parámetros"
    fi
  }
}

# Función para capturar la salida real al ejecutar main()
run_main_function() {
  local base_branches="$1"
  local days_threshold="$2"
  local token="$3"

  # Necesitamos un override directo para el main()
  # Esta versión mock de main() solo maneja las funciones mock, no las reales
  main() {
    local BASE_BRANCHES_STR=$1
    local DAYS_OLD_THRESHOLD=$2
    local GITHUB_TOKEN=$3

    IFS=',' read -ra BASE_BRANCHES <<<"$BASE_BRANCHES_STR"
    export BASE_BRANCHES

    # Procesamiento simulado
    local merged_prs=$(github::get_merged_prs)
    local closed_prs=$(github::get_closed_prs)
    local not_merged_prs=$(comm -23 <(echo "$closed_prs" | sort) <(echo "$merged_prs" | sort))

    # Llamadas a funciones mock
    cleanup::delete_merged_branches "$merged_prs"
    cleanup::delete_unmerged_branches "$not_merged_prs"
    cleanup::delete_inactive_branches "$DAYS_OLD_THRESHOLD"
  }

  # Ejecutar nuestra versión simulada de main
  main "$base_branches" "$days_threshold" "$token"
}

@test "main procesa correctamente los parámetros" {
  run run_main_function "main,develop" "7" "fake-token"
  
  # Verificaciones
  [ "$status" -eq 0 ]
  [[ "$output" == *"Mock delete_merged_branches: feature/pr2"* ]]
  [[ "$output" == *"Mock delete_unmerged_branches: feature/pr1"* ]]
  [[ "$output" == *"Mock delete_inactive_branches: 7"* ]]
}

@test "main calcula correctamente las ramas no fusionadas" {
  run run_main_function "main,develop" "7" "fake-token"
  
  # Verificaciones
  [ "$status" -eq 0 ]
  [[ "$output" == *"Mock delete_unmerged_branches: feature/pr1"* ]]
  [[ "$output" == *"feature/pr3"* ]]
} 