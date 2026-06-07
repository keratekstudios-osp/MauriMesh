#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================================"
echo "FIX REPLIT JAVA 17 FOR MAURIMESH ANDROID BUILDS"
echo "============================================================"
echo ""

ROOT="/home/runner/workspace"
BACKUP="$ROOT/backup-before-java17-fix-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP"

cd "$ROOT"

echo ""
echo "1. Backup Replit/Nix files"
[ -f replit.nix ] && cp replit.nix "$BACKUP/replit.nix"
[ -f .replit ] && cp .replit "$BACKUP/.replit"

echo "Backup saved to: $BACKUP"

echo ""
echo "2. Current Java status"
command -v java || true
java -version || true
echo "JAVA_HOME=${JAVA_HOME:-not set}"

echo ""
echo "3. Create/repair replit.nix with Java 17"
cat > replit.nix <<'NIX'
{ pkgs }: {
  deps = [
    pkgs.nodejs_20
    pkgs.corepack
    pkgs.jdk17
    pkgs.android-tools
    pkgs.unzip
    pkgs.zip
    pkgs.git
    pkgs.curl
    pkgs.wget
    pkgs.bash
    pkgs.pkg-config
    pkgs.cmake
    pkgs.ninja
    pkgs.rustc
    pkgs.cargo
  ];

  env = {
    JAVA_HOME = "${pkgs.jdk17}";
  };
}
NIX

echo ""
echo "4. Add shell Java fallback helper"
cat > maurimesh-java-env.sh <<'ENV'
#!/usr/bin/env bash

if command -v java >/dev/null 2>&1; then
  JAVA_BIN="$(readlink -f "$(command -v java)")"
  export JAVA_HOME="$(dirname "$(dirname "$JAVA_BIN")")"
  export PATH="$JAVA_HOME/bin:$PATH"
fi

echo "JAVA_HOME=$JAVA_HOME"
java -version
ENV

chmod +x maurimesh-java-env.sh

echo ""
echo "============================================================"
echo "JAVA 17 CONFIG WRITTEN"
echo "============================================================"
echo ""
echo "IMPORTANT:"
echo "Replit may need the shell/environment restarted for replit.nix to apply."
echo ""
echo "Next steps:"
echo "1. Stop and restart the Replit Shell, or press Run once."
echo "2. Then run:"
echo "   cd /home/runner/workspace"
echo "   source ./maurimesh-java-env.sh"
echo "   java -version"
echo "   echo \$JAVA_HOME"
echo ""
