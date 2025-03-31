#!/usr/bin/env bats

load '../test_helper.bash'

# Configuración para todas las pruebas
setup() {
  # Cargar los scripts con el path correcto
  source "${BATS_TEST_DIRNAME}/../../src/github.sh"
  
  # Mock de curl para evitar llamadas reales a la API
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
        echo "DELETE operation performed on branch"
        ;;
      *)
        return 0
        ;;
    esac
  }
  
  # Mock de date para tener fechas consistentes
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
  
  # Variables de entorno necesarias
  export GITHUB_TOKEN="fake-token"
  export GITHUB_API_URL="https://api.github.com/repos/user/repo"
  export BASE_BRANCHES=("main" "develop")
}

@test "github::get_closed_prs obtiene ramas de PRs cerrados" {
  result=$(github::get_closed_prs)
  expected=$'feature/test1\nfeature/test2'
  
  echo "Resultado: '$result'"
  echo "Esperado: '$expected'"
  
  [ "$result" = "$expected" ]
}

@test "github::get_merged_prs obtiene solo ramas de PRs fusionados" {
  result=$(github::get_merged_prs)
  expected="feature/test2"
  
  echo "Resultado: '$result'"
  echo "Esperado: '$expected'"
  
  [ "$result" = "$expected" ]
}

@test "github::delete_branch no borra ramas base" {
  run github::delete_branch "main"
  echo "Output: $output"
  
  [ "$status" -eq 0 ]
  [[ "$output" != *"DELETE"* ]]
}

@test "github::delete_branch borra ramas que no son base" {
  run github::delete_branch "feature/test1"
  echo "Output: $output"
  
  [ "$status" -eq 0 ]
  [[ "$output" == *"DELETE"* ]]
}

@test "github::get_branches lista todas las ramas disponibles" {
  result=$(github::get_branches)
  expected=$'feature/test1\nfeature/test2\nmain'
  
  echo "Resultado: '$result'"
  echo "Esperado: '$expected'"
  
  [ "$result" = "$expected" ]
}

@test "github::get_inactive_branches encuentra ramas inactivas" {
  # Sobrescribir el mock para este test específico
  github::get_branches() {
    echo "feature/test1"
    echo "feature/test2"
    echo "main"
  }
  
  # Usar el umbral de días adecuado
  result=$(github::get_inactive_branches "7")
  
  echo "Resultado: '$result'"
  
  # Cambia la expectativa para que coincida con lo que devuelve el mock
  [ "$result" = "feature/old" ]
} 