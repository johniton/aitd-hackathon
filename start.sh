#!/bin/bash
# ═══════════════════════════════════════════════════════
#  GoaGreen — Full Stack Startup Script
#  Run from project root: ./start.sh
# ═══════════════════════════════════════════════════════

set -e
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Colors
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}"
echo "═══════════════════════════════════════════════════════"
echo "  🌿 GoaGreen — Starting All Services"
echo "═══════════════════════════════════════════════════════"
echo -e "${NC}"

# ── 1. Kill any existing processes on ports 8000 and 3000 ──
echo -e "${YELLOW}[1/5] Cleaning up old processes...${NC}"
fuser -k 8000/tcp 2>/dev/null || true
fuser -k 3000/tcp 2>/dev/null || true
sleep 1
echo -e "${GREEN}  ✓ Ports 8000 & 3000 cleared${NC}"

# ── 2. Start Backend (FastAPI) ──
echo -e "${YELLOW}[2/5] Starting Backend (FastAPI on :8000)...${NC}"
cd "$ROOT_DIR/backend"
if [ -d "venv" ]; then
    source venv/bin/activate
fi
uvicorn main:app --reload --host 0.0.0.0 --port 8000 &
BACKEND_PID=$!
echo -e "${GREEN}  ✓ Backend started (PID: $BACKEND_PID)${NC}"

# ── 3. Start Sneaky API (Node.js on :3000) ──
echo -e "${YELLOW}[3/5] Starting Sneaky API (Node.js on :3000)...${NC}"
cd "$ROOT_DIR/sneaky-api-flexible"
node server.js &
SNEAKY_PID=$!
echo -e "${GREEN}  ✓ Sneaky API started (PID: $SNEAKY_PID)${NC}"

# ── 4. ADB Reverse Port Forwarding ──
echo -e "${YELLOW}[4/5] Setting up ADB reverse port forwarding...${NC}"
adb reverse tcp:8000 tcp:8000 2>/dev/null && echo -e "${GREEN}  ✓ ADB reverse :8000 → :8000${NC}" || echo -e "${RED}  ✗ ADB reverse :8000 failed (is device connected?)${NC}"
adb reverse tcp:3000 tcp:3000 2>/dev/null && echo -e "${GREEN}  ✓ ADB reverse :3000 → :3000${NC}" || echo -e "${RED}  ✗ ADB reverse :3000 failed (is device connected?)${NC}"

# ── 5. Start Flutter App ──
echo -e "${YELLOW}[5/5] Launching Flutter app...${NC}"
cd "$ROOT_DIR/frontend"

echo -e "${CYAN}"
echo "═══════════════════════════════════════════════════════"
echo "  🚀 All services running!"
echo "═══════════════════════════════════════════════════════"
echo -e "  Backend   → http://localhost:8000  (PID: $BACKEND_PID)"
echo -e "  Sneaky    → http://localhost:3000  (PID: $SNEAKY_PID)"
echo -e "  ADB       → ports 8000 & 3000 forwarded"
echo -e "  Flutter   → launching below..."
echo "═══════════════════════════════════════════════════════"
echo -e "${NC}"

# Flutter runs in foreground so you can interact with it (hot reload etc.)
flutter run

# ── Cleanup on exit ──
echo -e "\n${YELLOW}Shutting down services...${NC}"
kill $BACKEND_PID 2>/dev/null || true
kill $SNEAKY_PID 2>/dev/null || true
echo -e "${GREEN}All services stopped. Goodbye! 🌿${NC}"
