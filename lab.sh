#!/usr/bin/env bash
set -euo pipefail

LAB_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_SLUG="$(basename "$LAB_DIR" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9_-]/-/g')"
PROJECT="${LAB_PROJECT:-auditoria-${PROJECT_SLUG}}"

if [[ ! "$PROJECT" =~ ^[a-z0-9][a-z0-9_-]*$ ]]; then
  printf 'Nome de projeto Docker inválido: %s\n' "$PROJECT" >&2
  exit 2
fi

compose() {
  docker compose --project-name "$PROJECT" --file "$LAB_DIR/compose.yaml" "$@"
}

usage() {
  printf 'Uso: %s {up|shell|status|logs|collect|down}\n' "$0" >&2
  exit 2
}

case "${1:-}" in
  up)
    compose up --build --detach
    ;;
  shell)
    compose exec --interactive --tty auditoria bash
    ;;
  status)
    compose ps
    ;;
  logs)
    compose logs --follow --tail=50 auditoria
    ;;
  collect)
    mkdir -p "$LAB_DIR/entrega"
    compose cp auditoria:/home/aluno/entrega/relatorio.md "$LAB_DIR/entrega/relatorio.md"
    printf 'Relatório copiado para %s/entrega/relatorio.md\n' "$LAB_DIR"
    ;;
  down)
    compose down
    ;;
  *)
    usage
    ;;
esac
