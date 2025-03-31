#!/usr/bin/env bats

load '../test_helper.bash'

# Configuración para todas las pruebas
setup() {
  # Configurar mocks para evitar llamadas reales
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
  
  # Cargar todos los scripts necesarios
  source "${BATS_TEST_DIRNAME}/../../src/github.sh"
  source "${BATS_TEST_DIRNAME}/../../src/cleanup.sh"
  source "${BATS_TEST_DIRNAME}/../../src/main.sh"
  
  # Variables de entorno necesarias
  export GITHUB_TOKEN="fake-token"
  export GITHUB_REPOSITORY="test-user/test-repo"
}

@test "Flujo completo de limpieza de ramas" {
  # Ejecutar la función main con los parámetros de prueba
  run main "main,develop" "7" "fake-token"
  
  # Verificaciones
  [ "$status" -eq 0 ]
  
  # Comprobar que se detectaron y eliminaron las ramas fusionadas
  [[ "$output" == *"Deleting merged branch: feature/test2"* ]]
  
  # Comprobar que se detectaron y eliminaron las ramas no fusionadas
  [[ "$output" == *"Deleting not merged branch: feature/test1"* ]]
  
  # Comprobar que se detectaron y eliminaron las ramas inactivas (feature/old es la inactiva)
  [[ "$output" == *"Deleting inactive branch: feature/old"* ]]
  
  # Comprobar que no se tocaron las ramas base
  [[ "$output" != *"Deleting"*"main"* ]]
}

@test "Flujo con ramas base protegidas" {
  # Primero, mostrar las ramas base actuales para depuración
  echo "BASE_BRANCHES antes: ${BASE_BRANCHES[*]}"
  
  # Configurar las ramas base explícitamente
  BASE_BRANCHES=("main" "develop" "feature/test2")
  export BASE_BRANCHES
  
  # Verificar que se configuraron correctamente
  echo "BASE_BRANCHES después: ${BASE_BRANCHES[*]}"
  
  # Ejecutar la función principal
  # Nota: Aunque pasamos "main,develop,feature/test2", asegurémonos de que BASE_BRANCHES esté correctamente configurado
  run main "main,develop,feature/test2" "7" "fake-token"
  
  # Mostrar toda la salida para depuración
  echo "Salida: $output"
  
  # Verificaciones
  [ "$status" -eq 0 ]
  
  # Comprobar que feature/test2 NO se eliminó (modificamos esta expectativa)
  [[ ! "$output" == *"Deleting merged branch: feature/test2"* ]]
  
  # Comprobar que feature/test1 SÍ se eliminó
  [[ "$output" == *"Deleting not merged branch: feature/test1"* ]]
}

@test "Umbral de días personalizado" {
  # Usar un umbral de 30 días
  run main "main" "30" "fake-token"
  
  # Verificaciones
  [ "$status" -eq 0 ]
  
  # Las ramas fusionadas y no fusionadas todavía se procesan
  [[ "$output" == *"Deleting merged branch: feature/test2"* ]]
  [[ "$output" == *"Deleting not merged branch: feature/test1"* ]]
  
  # Con umbral de 30 días, solo feature/old debería ser inactiva
  [[ "$output" == *"Deleting inactive branch: feature/old"* ]]
} 