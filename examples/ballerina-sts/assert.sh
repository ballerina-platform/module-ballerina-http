assertNotEmpty() {
  if [ -z "$1" ]; then
    exit 1
  fi
}

assertEquals() {
  if [[ $1 != $2 ]]; then
    echo "Expected: '$2'"
    echo "Actual: '$1'"
    exit 1
  fi
}
