#!/usr/bin/env bats

load '../test_helper.bash'

# Configuración para todas las pruebas
setup() {
  # Cargar los scripts con el path correcto
  source "${BATS_TEST_DIRNAME}/../../src/cleanup.sh"
  
  # Mock de la función github::delete_branch
  github::delete_branch() {
    local branch=$1
    if [[ " ${BASE_BRANCHES[*]} " == *" $branch "* ]]; then
      echo "PROTECTED: No se borra la rama base $branch"
    else
      echo "DELETED: Se ha borrado la rama $branch"
    fi
  }
  
  # Mock de github::get_inactive_branches
  github::get_inactive_branches() {
    local days=$1
    echo "feature/old"
    echo "feature/stale"
  }
  
  # Variables de entorno necesarias
  export BASE_BRANCHES=("main" "develop")
}

@test "cleanup::delete_merged_branches elimina todas las ramas fusionadas" {
  # Preparación de datos de prueba
  local merged_branches=$'feature/merged1\nfeature/merged2\nmain'
  
  # Ejecutar la función bajo prueba
  run cleanup::delete_merged_branches "$merged_branches"
  
  # Verificaciones
  [ "$status" -eq 0 ]
  [[ "$output" == *"feature/merged1"* ]]
  [[ "$output" == *"feature/merged2"* ]]
  [[ "$output" == *"DELETED: Se ha borrado la rama feature/merged1"* ]]
  [[ "$output" == *"DELETED: Se ha borrado la rama feature/merged2"* ]]
  [[ "$output" == *"PROTECTED: No se borra la rama base main"* ]]
}

@test "cleanup::delete_unmerged_branches elimina ramas cerradas sin fusionar" {
  # Preparación de datos de prueba
  local unmerged_branches=$'feature/unmerged1\nfeature/unmerged2'
  
  # Ejecutar la función bajo prueba
  run cleanup::delete_unmerged_branches "$unmerged_branches"
  
  # Verificaciones
  [ "$status" -eq 0 ]
  [[ "$output" == *"feature/unmerged1"* ]]
  [[ "$output" == *"feature/unmerged2"* ]]
  [[ "$output" == *"DELETED: Se ha borrado la rama feature/unmerged1"* ]]
  [[ "$output" == *"DELETED: Se ha borrado la rama feature/unmerged2"* ]]
}

@test "cleanup::delete_inactive_branches elimina ramas inactivas" {
  # Ejecutar la función bajo prueba
  run cleanup::delete_inactive_branches "7"
  
  # Verificaciones
  [ "$status" -eq 0 ]
  [[ "$output" == *"feature/old"* ]]
  [[ "$output" == *"feature/stale"* ]]
  [[ "$output" == *"DELETED: Se ha borrado la rama feature/old"* ]]
  [[ "$output" == *"DELETED: Se ha borrado la rama feature/stale"* ]]
} 