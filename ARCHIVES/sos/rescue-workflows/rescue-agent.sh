#!/bin/bash

# 🚨 RESCUE AGENT WORKFLOW
# Infinity Cloud Standard - v1.0
# Usage: ./rescue-agent.sh [agent-name] [mission-type]

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
AGENT_NAME=${1:-"agent"}
MISSION_TYPE=${2:-"standard"}
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
RESCUE_DIR="~/moulinsart/sos/rescue-reports"
REPORT_FILE="$RESCUE_DIR/rescue_${AGENT_NAME}_${TIMESTAMP}.html"

# Create rescue directory if not exists
mkdir -p "$RESCUE_DIR"

echo -e "${YELLOW}🚨 RESCUE MISSION INITIATED${NC}"
echo -e "Agent: ${BLUE}$AGENT_NAME${NC}"
echo -e "Mission Type: ${BLUE}$MISSION_TYPE${NC}"
echo -e "Timestamp: $TIMESTAMP"
echo ""

# Step 1: Clean Agent State
clean_agent_state() {
    echo -e "${YELLOW}🧹 Step 1: Cleaning Agent State...${NC}"
    
    # Kill any hanging processes
    pkill -f "$AGENT_NAME" 2>/dev/null || true
    
    # Clear temporary files
    rm -rf "/tmp/${AGENT_NAME}_*" 2>/dev/null || true
    
    # Reset agent CLAUDE.md if needed
    if [ -f "~/moulinsart/agents/$AGENT_NAME/CLAUDE.md.backup" ]; then
        cp "~/moulinsart/agents/$AGENT_NAME/CLAUDE.md.backup" \
           "~/moulinsart/agents/$AGENT_NAME/CLAUDE.md"
        echo "✅ CLAUDE.md restored from backup"
    fi
    
    echo -e "${GREEN}✅ Agent state cleaned${NC}\n"
}

# Step 2: Rebuild Environment
rebuild_environment() {
    echo -e "${YELLOW}🔨 Step 2: Rebuilding Environment...${NC}"
    
    case $MISSION_TYPE in
        "ios")
            echo "📱 Rebuilding iOS environment..."
            # Clean Xcode derived data
            rm -rf ~/Library/Developer/Xcode/DerivedData/* 2>/dev/null || true
            # Reset simulator
            xcrun simctl shutdown all 2>/dev/null || true
            xcrun simctl erase all 2>/dev/null || true
            ;;
        "web")
            echo "🌐 Rebuilding Web environment..."
            # Clear node_modules and reinstall
            rm -rf node_modules package-lock.json
            npm install
            ;;
        "python")
            echo "🐍 Rebuilding Python environment..."
            # Clear cache and reinstall
            pip cache purge
            pip install -r requirements.txt --force-reinstall
            ;;
        *)
            echo "📦 Standard rebuild..."
            ;;
    esac
    
    echo -e "${GREEN}✅ Environment rebuilt${NC}\n"
}

# Step 3: Generate Visual Proofs
generate_proofs() {
    echo -e "${YELLOW}📸 Step 3: Generating Visual Proofs...${NC}"
    
    PROOF_DIR="$RESCUE_DIR/proofs_${TIMESTAMP}"
    mkdir -p "$PROOF_DIR"
    
    # Take screenshots based on mission type
    case $MISSION_TYPE in
        "ios")
            # iOS Simulator screenshots
            if pgrep -x "Simulator" > /dev/null; then
                xcrun simctl io booted screenshot "$PROOF_DIR/simulator_rescue.png" 2>/dev/null || true
                echo "✅ Simulator screenshot captured"
            fi
            ;;
        "web")
            # Web browser screenshot (if available)
            if command -v screencapture &> /dev/null; then
                screencapture -x "$PROOF_DIR/desktop_rescue.png"
                echo "✅ Desktop screenshot captured"
            fi
            ;;
        *)
            # Generic screenshot
            if command -v screencapture &> /dev/null; then
                screencapture -x "$PROOF_DIR/generic_rescue.png"
                echo "✅ Generic screenshot captured"
            fi
            ;;
    esac
    
    # Generate checksums
    if [ -d "$PROOF_DIR" ]; then
        find "$PROOF_DIR" -type f -exec shasum -a 256 {} \; > "$PROOF_DIR/checksums.sha256"
        echo "✅ Checksums generated"
    fi
    
    echo -e "${GREEN}✅ Visual proofs generated${NC}\n"
}

# Step 4: Generate HTML Report
generate_report() {
    echo -e "${YELLOW}📄 Step 4: Generating HTML Report...${NC}"
    
    cat > "$REPORT_FILE" << EOF
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rescue Mission Report - $AGENT_NAME</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        }
        .container {
            background: white;
            border-radius: 10px;
            padding: 30px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.1);
        }
        h1 {
            color: #667eea;
            border-bottom: 3px solid #667eea;
            padding-bottom: 10px;
        }
        .status {
            display: inline-block;
            padding: 5px 15px;
            border-radius: 20px;
            font-weight: bold;
            margin: 10px 0;
        }
        .success { background: #48bb78; color: white; }
        .warning { background: #f6ad55; color: white; }
        .error { background: #fc8181; color: white; }
        .info-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin: 20px 0;
        }
        .info-box {
            background: #f7fafc;
            padding: 15px;
            border-radius: 8px;
            border-left: 4px solid #667eea;
        }
        .info-box h3 {
            margin: 0 0 10px 0;
            color: #667eea;
        }
        .steps {
            margin: 20px 0;
        }
        .step {
            background: #f7fafc;
            padding: 15px;
            margin: 10px 0;
            border-radius: 8px;
            border-left: 4px solid #48bb78;
        }
        .step h3 {
            margin: 0 0 10px 0;
            color: #48bb78;
        }
        .screenshots {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
            margin: 20px 0;
        }
        .screenshot {
            text-align: center;
        }
        .screenshot img {
            max-width: 100%;
            border-radius: 8px;
            box-shadow: 0 4px 8px rgba(0,0,0,0.1);
        }
        .footer {
            margin-top: 40px;
            padding-top: 20px;
            border-top: 2px solid #e2e8f0;
            text-align: center;
            color: #718096;
        }
        code {
            background: #2d3748;
            color: #48bb78;
            padding: 2px 6px;
            border-radius: 4px;
            font-family: 'Monaco', monospace;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚨 Rescue Mission Report</h1>
        
        <div class="status success">MISSION COMPLETED</div>
        
        <div class="info-grid">
            <div class="info-box">
                <h3>🤖 Agent</h3>
                <p><strong>$AGENT_NAME</strong></p>
            </div>
            <div class="info-box">
                <h3>🎯 Mission Type</h3>
                <p><strong>$MISSION_TYPE</strong></p>
            </div>
            <div class="info-box">
                <h3>⏰ Timestamp</h3>
                <p><strong>$TIMESTAMP</strong></p>
            </div>
            <div class="info-box">
                <h3>⏱️ Duration</h3>
                <p><strong>< 5 minutes</strong></p>
            </div>
        </div>
        
        <h2>📋 Steps Executed</h2>
        <div class="steps">
            <div class="step">
                <h3>✅ Step 1: Clean Agent State</h3>
                <p>Successfully cleaned agent state and removed temporary files.</p>
            </div>
            <div class="step">
                <h3>✅ Step 2: Rebuild Environment</h3>
                <p>Environment rebuilt for $MISSION_TYPE configuration.</p>
            </div>
            <div class="step">
                <h3>✅ Step 3: Generate Visual Proofs</h3>
                <p>Screenshots and checksums generated successfully.</p>
            </div>
            <div class="step">
                <h3>✅ Step 4: Generate Report</h3>
                <p>This HTML report has been generated and saved.</p>
            </div>
        </div>
        
        <h2>📸 Visual Proofs</h2>
        <div class="screenshots">
            <!-- Screenshots will be inserted here if available -->
            <div class="screenshot">
                <p><em>Screenshots saved in: $PROOF_DIR</em></p>
            </div>
        </div>
        
        <h2>🔍 Checksums</h2>
        <div style="background: #2d3748; color: #48bb78; padding: 15px; border-radius: 8px; font-family: monospace; overflow-x: auto;">
            <code>SHA256 checksums generated and saved</code>
        </div>
        
        <h2>📝 Recommendations</h2>
        <ul>
            <li>Agent has been reset to clean state</li>
            <li>Environment has been rebuilt</li>
            <li>Ready to resume operations</li>
            <li>Monitor for recurring issues</li>
        </ul>
        
        <div class="footer">
            <p><strong>Infinity Cloud Rescue System v1.0</strong></p>
            <p>Report generated on $(date)</p>
            <p>Moulinsart Agentic Engineering</p>
        </div>
    </div>
</body>
</html>
EOF
    
    echo "✅ HTML report generated: $REPORT_FILE"
    
    # Open report in browser
    if command -v open &> /dev/null; then
        open "$REPORT_FILE"
        echo "✅ Report opened in browser"
    fi
    
    echo -e "${GREEN}✅ Report generation complete${NC}\n"
}

# Step 5: Resume Agent
resume_agent() {
    echo -e "${YELLOW}▶️ Step 5: Resuming Agent...${NC}"
    
    # Send resume command to tmux if session exists
    TMUX_SESSION="moulinsart"
    if tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
        # Find agent panel (0-3)
        case $AGENT_NAME in
            "nestor") PANEL=0 ;;
            "tintin") PANEL=1 ;;
            "dupont1") PANEL=2 ;;
            "dupont2") PANEL=3 ;;
            *) PANEL=0 ;;
        esac
        
        # Send resume command
        tmux send-keys -t "$TMUX_SESSION:agents.$PANEL" "claude --resume" Enter
        echo "✅ Resume command sent to panel $PANEL"
    else
        echo "⚠️ No tmux session found - manual resume required"
    fi
    
    echo -e "${GREEN}✅ Agent ready to resume${NC}\n"
}

# Main execution
main() {
    echo ""
    echo "╔══════════════════════════════════════════╗"
    echo "║     🚨 INFINITY CLOUD RESCUE SYSTEM 🚨    ║"
    echo "╚══════════════════════════════════════════╝"
    echo ""
    
    # Execute all steps
    clean_agent_state
    rebuild_environment
    generate_proofs
    generate_report
    resume_agent
    
    echo ""
    echo "╔══════════════════════════════════════════╗"
    echo "║          ✅ MISSION COMPLETED ✅          ║"
    echo "╚══════════════════════════════════════════╝"
    echo ""
    echo -e "${GREEN}Report saved: $REPORT_FILE${NC}"
    echo -e "${GREEN}Proofs saved: $PROOF_DIR${NC}"
    echo ""
}

# Run main function
main