#!/usr/bin/env bash
# Aplica labels.yml em todos os repos da organização. Idempotente.
# Uso: scripts/apply-labels.sh [org]   (requer gh autenticado e python3 com PyYAML)
set -euo pipefail

org="${1:-Gorila-Software-House}"
labels_file="$(dirname "$0")/../labels.yml"

# Renomeia (preserva issues já marcadas); ignora se a label antiga não existe.
declare -A renames=(
  [enhancement]="melhoria"
  [documentation]="documentação"
  [duplicate]="duplicado"
  [wontfix]="não vai ser feito"
  [question]="dúvida"
)

labels_as_tsv() {
  python3 -c '
import sys, yaml
for l in yaml.safe_load(open(sys.argv[1])):
    print("\t".join([l["name"], l["color"], l["description"]]))
' "$labels_file"
}

apply_to_repo() {
  local repo="$1" old new name color description
  for old in "${!renames[@]}"; do
    new="${renames[$old]}"
    gh label edit "$old" --name "$new" -R "$org/$repo" 2>/dev/null || true
  done
  while IFS=$'\t' read -r name color description; do
    gh label create "$name" --color "$color" --description "$description" --force -R "$org/$repo" >/dev/null
  done < <(labels_as_tsv)
  echo "ok  $repo"
}

while read -r repo; do
  apply_to_repo "$repo" || echo "ERRO $repo"
done < <(gh repo list "$org" --limit 200 --no-archived --json name --jq '.[].name')
