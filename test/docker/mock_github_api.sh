#!/bin/bash
set -e

# Mock de la API de GitHub usando un servidor local
# Creamos una mini API HTTP simulada con archivos y netcat

# Directorio para almacenar las respuestas de la API
API_DIR="/tmp/github_api"
mkdir -p "${API_DIR}/repos/test-user/test-repo"

# Crear respuestas para cada endpoint
echo '[{"head": {"ref": "feature/test1"}}, {"head": {"ref": "feature/test2"}, "merged_at": "2023-01-01"}]' > "${API_DIR}/repos/test-user/test-repo/pulls_closed"
echo '[{"name": "main"}, {"name": "develop"}, {"name": "feature/old"}, {"name": "feature/new"}]' > "${API_DIR}/repos/test-user/test-repo/branches"
echo '{"commit": {"commit": {"committer": {"date": "2020-01-01T00:00:00Z"}}}}' > "${API_DIR}/repos/test-user/test-repo/branch_old"
echo '{"commit": {"commit": {"committer": {"date": "2023-01-10T00:00:00Z"}}}}' > "${API_DIR}/repos/test-user/test-repo/branch_new"

# Función para simular curl con archivos locales
function mock_curl() {
  local url="$*"
  
  # Definir API_DIR en caso de que no esté disponible en el entorno
  local API_DIR="${API_DIR:-/tmp/github_api}"
  
  # Si MOCK_ERROR está definido y es 1, simular un error
  if [[ -n "${MOCK_ERROR:-}" && "${MOCK_ERROR:-}" -eq 1 ]]; then
    echo "MOCK API ERROR: Simulando error de API" >&2
    return 1
  fi
  
  # Extraer el comando (GET, DELETE, etc.) y la URL
  local command
  local endpoint
  command=$(echo "$url" | grep -o -E '(GET|DELETE|POST|PUT)' || echo "GET")
  endpoint=$(echo "$url" | grep -o -E 'https://api.github.com/repos/[^ ]+')
  endpoint=${endpoint#https://api.github.com/}
  
  echo "MOCK API REQUEST: $command $endpoint" >&2
  
  # Simular diferentes endpoints
  case "$endpoint" in
    "repos/test-user/test-repo/pulls?state=closed")
      cat "${API_DIR}/repos/test-user/test-repo/pulls_closed"
      ;;
    "repos/test-user/test-repo/branches?protected=false")
      cat "${API_DIR}/repos/test-user/test-repo/branches"
      ;;
    *"branches/feature/old"*)
      cat "${API_DIR}/repos/test-user/test-repo/branch_old"
      ;;
    *"branches/feature/new"*)
      cat "${API_DIR}/repos/test-user/test-repo/branch_new"
      ;;
    *"git/refs/heads/"*)
      if [[ "$command" == "DELETE" ]]; then
        local branch
        branch=${endpoint##*/heads/}
        echo "MOCK API: Deleted branch $branch" >&2
        echo '{}'
      else
        echo '{}'
      fi
      ;;
    *)
      echo "MOCK API: Unknown endpoint $endpoint" >&2
      echo '{}'
      ;;
  esac
}

# Exportar la función para que se use en lugar de curl
export -f mock_curl

# Reemplazar la función curl con nuestra versión mockeada
function curl() {
  mock_curl "$@"
}
export -f curl

# Función para simular date
function date() {
  if [[ "$*" == *"--date="* ]]; then
    # Extracción del número de días
    if [[ "$*" =~ --date=([0-9]+)\ day\ ago ]]; then
      local days=${BASH_REMATCH[1]}
      echo "2023-01-$((12 - days))T00:00:00Z"
    else
      echo "2023-01-12T00:00:00Z"
    fi
  elif [[ "$*" == *"-d "* ]]; then
    # Convertir fecha a timestamp
    if [[ "$*" =~ -d\ ([0-9]{4}-[0-9]{2}-[0-9]{2}) ]]; then
      local year=${BASH_REMATCH[1]:0:4}
      local month=${BASH_REMATCH[1]:5:2}
      local day=${BASH_REMATCH[1]:8:2}
      echo $(( (year - 1970) * 365 * 24 * 3600 + month * 30 * 24 * 3600 + day * 24 * 3600 ))
    else
      echo "1672531200" # Un valor por defecto
    fi
  else
    echo "2023-01-12T00:00:00Z"
  fi
}
export -f date 