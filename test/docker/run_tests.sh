#!/bin/bash
set -e

echo "===== INICIANDO PRUEBAS DOCKER DE BRANCHES CLEANER ====="

# Inicializar variables para controlar los resultados
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# Cargar el mock de la API de GitHub
echo "Cargando mock de la API de GitHub..."
# shellcheck disable=SC1091
source "/github/workspace/test/docker/mock_github_api.sh"

# Función para ejecutar un test y verificar su salida
run_test() {
  local test_name="$1"
  local cmd="$2"
  local expected_output="$3"
  
  echo ""
  echo "===== Ejecutando test: $test_name ====="
  echo "Comando: $cmd"
  echo ""
  
  TESTS_TOTAL=$((TESTS_TOTAL + 1))
  
  # Ejecutar el comando y capturar su salida
  local output
  local exit_code
  output=$(eval "$cmd")
  exit_code=$?
  
  # Verificar si la salida contiene lo esperado
  if [ $exit_code -eq 0 ] && [[ "$output" == *"$expected_output"* ]]; then
    echo "✅ Test pasado: $test_name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo "❌ Test fallido: $test_name"
    echo "Salida obtenida:"
    echo "$output"
    echo "Salida esperada debe contener:"
    echo "$expected_output"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

# Test 1: Prueba básica con ramas base predeterminadas
run_test "Prueba básica" \
  "/github/workspace/entrypoint.sh 'main,develop' '7' 'fake-token'" \
  "Deleting merged branch: feature/test2"

# Test 2: Prueba con umbral de días personalizado
run_test "Umbral de días personalizado" \
  "/github/workspace/entrypoint.sh 'main,develop' '1' 'fake-token'" \
  "Deleting inactive branch: feature/old"

# Test 3: Prueba protegiendo una rama específica
run_test "Protección de rama específica" \
  "/github/workspace/entrypoint.sh 'main,develop,feature/test2' '7' 'fake-token'" \
  "Deleting not merged branch: feature/test1"

# Test 4: Comprobar que el script maneja correctamente los errores (curl simulado)
run_test "Manejo de errores" \
  "MOCK_ERROR=1 /github/workspace/entrypoint.sh 'main' '7' 'fake-token' || echo 'Error detectado correctamente'" \
  "Error detectado correctamente"

# Ejecutar las pruebas Bats si están disponibles
if command -v bats &> /dev/null; then
  echo ""
  echo "===== Ejecutando pruebas Bats ====="
  cd /github/workspace && bats /github/workspace/test/bats
fi

# Resumen de los resultados
echo ""
echo "===== RESUMEN DE PRUEBAS DOCKER ====="
echo "Tests totales: $TESTS_TOTAL"
echo "Tests pasados: $TESTS_PASSED"
echo "Tests fallidos: $TESTS_FAILED"

# Finalizar con el código de salida adecuado
if [ $TESTS_FAILED -eq 0 ]; then
  echo "✅ Todas las pruebas pasaron exitosamente"
  exit 0
else
  echo "❌ Algunas pruebas fallaron"
  exit 1
fi 