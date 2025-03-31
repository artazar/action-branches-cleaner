#!/usr/bin/env bash

# Helper para depuración y mensajes comunes
debug() {
  if [ "${BATS_DEBUG:-0}" -eq 1 ]; then
    echo "DEBUG: $*" >&3
  fi
}

# Función auxiliar para comparar las salidas esperadas con las reales
assert_output_contains() {
  local expected="$1"
  if [[ "$output" != *"$expected"* ]]; then
    echo "La salida no contiene '$expected'" >&2
    echo "Salida real: $output" >&2
    return 1
  fi
}

assert_output_not_contains() {
  local unexpected="$1"
  if [[ "$output" == *"$unexpected"* ]]; then
    echo "La salida contiene '$unexpected' cuando no debería" >&2
    echo "Salida real: $output" >&2
    return 1
  fi
}

# Registrar información sobre el entorno de ejecución de pruebas
setup_file() {
  echo "Iniciando ejecución de pruebas con Bats en $(date)" >&3
  echo "Sistema: $(uname -a)" >&3
}

teardown_file() {
  echo "Finalizando ejecución de pruebas con Bats en $(date)" >&3
}

# Función para crear una estructura temporal para pruebas
create_test_branches() {
  local repo_dir="$1"
  
  mkdir -p "$repo_dir"
  cd "$repo_dir"
  
  git init -q
  git config --local user.email "test@example.com"
  git config --local user.name "Test User"
  
  # Crear rama principal
  echo "# Test Repository" > README.md
  git add README.md
  git commit -q -m "Initial commit"
  
  # Crear ramificaciones para pruebas
  git checkout -q -b feature/test1
  echo "Feature 1" > feature1.txt
  git add feature1.txt
  GIT_COMMITTER_DATE="2020-01-01T00:00:00Z" git commit -q --date="2020-01-01T00:00:00Z" -m "Feature 1 commit"
  
  git checkout -q -b feature/test2
  echo "Feature 2" > feature2.txt
  git add feature2.txt
  git commit -q -m "Feature 2 commit"
  
  git checkout -q master
}

# Limpiar después de las pruebas
cleanup_test_repo() {
  local repo_dir="$1"
  if [ -d "$repo_dir" ]; then
    rm -rf "$repo_dir"
  fi
} 