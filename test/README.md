# Pruebas para Branches Cleaner GitHub Action

Este directorio contiene las pruebas automatizadas para la GitHub Action "Branches Cleaner". La suite de pruebas incluye pruebas unitarias, de integración y funcionales para asegurar que la acción funcione correctamente.

## Estructura de Pruebas

```
test/
├── bats/                   # Pruebas unitarias con Bats
│   ├── github_test.bats    # Pruebas para github.sh
│   ├── cleanup_test.bats   # Pruebas para cleanup.sh
│   ├── main_test.bats      # Pruebas para main.sh
│   └── integration_test.bats # Pruebas de integración
├── docker/                 # Pruebas de integración con Docker
│   ├── Dockerfile.test     # Docker para ejecutar pruebas
│   ├── docker-compose.yml  # Configuración de Docker Compose
│   ├── mock_github_api.sh  # Mock de la API de GitHub
│   └── run_tests.sh        # Script de ejecución de pruebas
├── functional/             # Pruebas funcionales
│   └── workflow-test.yml   # Flujo de trabajo de GitHub Actions
├── test_helper.bash        # Funciones auxiliares para pruebas Bats
├── inactive_branches_test.sh # Prueba específica para detección de ramas inactivas
└── README.md               # Esta documentación
```

## Tipos de Pruebas

### 1. Pruebas Unitarias (Bats)

Las pruebas unitarias utilizan [Bats (Bash Automated Testing System)](https://github.com/bats-core/bats-core) para probar cada función de manera aislada:

- `github_test.bats`: Prueba las funciones en `github.sh` que interactúan con la API de GitHub.
- `cleanup_test.bats`: Prueba las funciones en `cleanup.sh` para eliminar diferentes tipos de ramas.
- `main_test.bats`: Prueba la lógica principal en `main.sh`.
- `integration_test.bats`: Pruebas combinadas de los distintos módulos.

### 2. Pruebas de Integración (Docker)

Las pruebas de integración utilizan Docker para simular un entorno cercano al de GitHub Actions:

- `Dockerfile.test`: Configura un contenedor similar al entorno de GitHub Actions.
- `mock_github_api.sh`: Simula las respuestas de la API de GitHub sin hacer llamadas reales.
- `run_tests.sh`: Ejecuta varios escenarios de prueba dentro del contenedor.

### 3. Pruebas Específicas

- `inactive_branches_test.sh`: Prueba específica para la función `github::get_inactive_branches` que detecta ramas inactivas.

### 4. Pruebas Funcionales (GitHub Actions)

- `workflow-test.yml`: Define un flujo de trabajo de GitHub Actions para probar la acción en un entorno real.

## Ejecución de Pruebas

### Pruebas Unitarias con Bats

```bash
# Instalar Bats (si no está instalado)
sudo apt-get install bats

# Ejecutar todas las pruebas Bats
bats test/bats

# Ejecutar un archivo de prueba específico
bats test/bats/github_test.bats
```

### Pruebas de Integración con Docker

```bash
# Construir y ejecutar las pruebas con Docker Compose
cd test/docker
docker-compose up --build
```

### Prueba Específica de Ramas Inactivas

```bash
# Ejecutar la prueba específica
chmod +x test/inactive_branches_test.sh
./test/inactive_branches_test.sh
```

### Pruebas Funcionales en GitHub Actions

Las pruebas funcionales se ejecutan automáticamente en GitHub Actions cuando:

1. Se hace push a la rama `main`
2. Se abre un pull request contra la rama `main`

## Flujo de Trabajo de CI

El proyecto incluye un flujo de trabajo de GitHub Actions para ejecutar todas las pruebas en integración continua. Consulte el archivo `.github/workflows/test.yml` para ver la configuración.

## Contribuciones a las Pruebas

Al contribuir con nuevas funcionalidades o correcciones a la acción, asegúrese de:

1. Añadir pruebas unitarias para las nuevas funciones o correcciones.
2. Verificar que todas las pruebas pasen antes de enviar un pull request.
3. Si es necesario, actualizar las pruebas existentes para reflejar cambios de comportamiento esperados.

## Solución de Problemas

Si las pruebas fallan:

1. Verifique que los mocks y stubs reflejen correctamente el comportamiento esperado.
2. Compruebe que las funciones probadas no tengan efectos secundarios inesperados.
3. Para pruebas de Docker, asegúrese de que la imagen se construya correctamente.
4. Para pruebas funcionales con GitHub Actions, compruebe los permisos del token.

## Referencias

- [Bats Testing Framework](https://github.com/bats-core/bats-core)
- [ShellCheck](https://www.shellcheck.net/)
- [GitHub Actions](https://docs.github.com/en/actions)
- [Docker Compose](https://docs.docker.com/compose/)
