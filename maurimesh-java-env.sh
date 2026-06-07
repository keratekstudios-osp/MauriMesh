#!/usr/bin/env bash

if command -v java >/dev/null 2>&1; then
  JAVA_BIN="$(readlink -f "$(command -v java)")"
  export JAVA_HOME="$(dirname "$(dirname "$JAVA_BIN")")"
  export PATH="$JAVA_HOME/bin:$PATH"
fi

echo "JAVA_HOME=$JAVA_HOME"
java -version
