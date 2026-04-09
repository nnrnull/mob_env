#!/bin/bash

# ==============================================================================
# SUB-SCRIPTS (Converted to functions)
# ==============================================================================

run_install_tools() {
# --- THEME COLORS ---
G='\033[0;32m'   # Green
C='\033[0;36m'   # Cyan
R='\033[0;31m'   # Red
Y='\033[1;33m'   # Yellow
NC='\033[0m'     # No Color

set -e

########################################
# CONFIG
########################################
SDK="$HOME/android-sdk"
LAB="$HOME/mobile-lab"
STUDIO_DIR="$HOME/android-studio"
API=31
FRIDA_VER="16.2.1"
# Android Studio Koala Feature Drop (2024.1.2)
STUDIO_VER="2024.1.2.12" 
STUDIO_URL="https://redirector.gvt1.com/edgedl/android/studio/ide-zips/$STUDIO_VER/android-studio-$STUDIO_VER-linux.tar.gz"

export ANDROID_SDK_ROOT="$SDK"
export PATH=$PATH:$SDK/platform-tools:$SDK/emulator:$SDK/cmdline-tools/latest/bin:$STUDIO_DIR/bin:$HOME/.local/bin

mkdir -p "$LAB"
mkdir -p "$HOME/bin" 

echo -e "${G}[+] Initializing System Audit...${NC}"

########################################
# 1. SYSTEM DEPENDENCIES
########################################
echo -e "${C}[Section 1] Verifying System Dependencies...${NC}"

# Fixed: Replaced libncurses5 with libncurses6 and libncurses-dev
PKGS=(
    default-jdk wget curl unzip xz-utils git cmake sqlite3 
    python3 python3-pip python3-venv pipx nodejs npm 
    adb zipalign apksigner qemu-system-x86 libvirt-daemon-system 
    libvirt-clients bridge-utils virt-manager docker.io 
    radare2 node-js-beautify build-essential
    libncurses6 libncurses-dev lib32z1 lib32stdc++6
)

# ... [The rest of your original logic for checking/installing PKGS remains the same] ...

MISSING_PKGS=()
for pkg in "${PKGS[@]}"; do
    if ! dpkg -s "$pkg" >/dev/null 2>&1; then
        MISSING_PKGS+=("$pkg")
    fi
done

if [ ${#MISSING_PKGS[@]} -gt 0 ]; then
    echo -e "${Y}[!] Missing packages found: ${MISSING_PKGS[*]}${NC}"
    sudo apt update
    sudo apt install -y "${MISSING_PKGS[@]}"
else
    echo -e "${G}[V] All system dependencies are already present.${NC}"
fi

########################################
# 2. PYTHON TOOLS (PIPX)
########################################
echo -e "${C}[Section 2] Verifying Pipx Toolset...${NC}"

pipx ensurepath --force >/dev/null 2>&1 || true

PIPX_TOOLS=(
    frida-tools objection mitmproxy drozer 
    apkid androguard quark-engine paranoid-deobfuscator
)

for tool in "${PIPX_TOOLS[@]}"; do
    if pipx list | grep -q "$tool"; then
        echo -e "${G}[V] $tool already installed.${NC}"
    else
        echo -e "${Y}[+] Installing $tool...${NC}"
        pipx install "$tool"
    fi
done

if ! pipx list | grep -q "hermes-dec"; then
    pipx install hermes-dec || true
fi

########################################
# 3. PYXAMSTORE
########################################
echo -e "${C}[Section 3] Verifying Pyxamstore...${NC}"

if [ -f "$HOME/.local/bin/pyxamstore" ]; then
    echo -e "${G}[V] Pyxamstore environment is active.${NC}"
else
    echo -e "${Y}[+] Building Pyxamstore source...${NC}"
    cd "$LAB"
    [ ! -d "pyxamstore" ] && git clone https://github.com/jakev/pyxamstore.git
    cd pyxamstore
    [ ! -d "pyxamstore-env" ] && python3 -m venv pyxamstore-env
    source pyxamstore-env/bin/activate
    pip install --upgrade pip setuptools wheel
    pip install .
    deactivate
    ln -sf "$LAB/pyxamstore/pyxamstore-env/bin/pyxamstore" "$HOME/.local/bin/pyxamstore"
fi

########################################
# 4. ANDROID SDK
########################################
echo -e "${C}[Section 4] Verifying Android SDK...${NC}"

if [ -f "$SDK/cmdline-tools/latest/bin/sdkmanager" ]; then
    echo -e "${G}[V] SDK Manager found.${NC}"
else
    echo -e "${Y}[+] Deploying Command Line Tools...${NC}"
    mkdir -p "$SDK/cmdline-tools"
    wget -q https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip -O /tmp/sdk.zip
    unzip -q /tmp/sdk.zip -d /tmp
    mkdir -p "$SDK/cmdline-tools/latest"
    mv /tmp/cmdline-tools/* "$SDK/cmdline-tools/latest/"
fi

yes | sdkmanager --licenses >/dev/null

# Component audit
COMPONENTS=("platform-tools" "emulator" "build-tools;31.0.0" "platforms;android-$API" "system-images;android-$API;google_apis;x86_64")
for comp in "${COMPONENTS[@]}"; do
    if sdkmanager --list_installed | grep -q "$comp"; then
        echo -e "${G}[V] SDK Component '$comp' is present.${NC}"
    else
        echo -e "${Y}[+] Installing SDK Component '$comp'...${NC}"
        sdkmanager --install "$comp"
    fi
done

########################################
# 5. RE TOOLS (JADX, APKTOOL, DEX2JAR)
########################################
echo -e "${C}[Section 5] Verifying Static Analysis Tools...${NC}"

# JADX
if [ -x "$(command -v jadx)" ]; then
    echo -e "${G}[V] JADX is present.${NC}"
else
    echo -e "${Y}[+] Downloading JADX...${NC}"
    JADX_VER="1.4.7"
    wget -q "https://github.com/skylot/jadx/releases/download/v$JADX_VER/jadx-$JADX_VER.zip" -O /tmp/jadx.zip
    unzip -q /tmp/jadx.zip -d "$LAB/jadx"
    ln -sf "$LAB/jadx/bin/jadx" "$HOME/.local/bin/jadx"
    ln -sf "$LAB/jadx/bin/jadx-gui" "$HOME/.local/bin/jadx-gui"
fi

# Apktool
if [ -f "$HOME/.local/bin/apktool" ]; then
    echo -e "${G}[V] Apktool is present.${NC}"
else
    echo -e "${Y}[+] Downloading Apktool...${NC}"
    wget -q https://raw.githubusercontent.com/iBotPeaches/Apktool/master/scripts/linux/apktool -O "$HOME/.local/bin/apktool"
    wget -q https://github.com/iBotPeaches/Apktool/releases/download/v2.9.3/apktool_2.9.3.jar -O "$HOME/.local/bin/apktool.jar"
    chmod +x "$HOME/.local/bin/apktool"
fi

# dex2jar
if [ -d "$LAB/dex2jar" ]; then
    echo -e "${G}[V] dex2jar is present.${NC}"
else
    echo -e "${Y}[+] Downloading dex2jar...${NC}"
    wget -q https://github.com/pxb1988/dex2jar/releases/download/v2.4/dex-tools-v2.4.zip -O /tmp/d2j.zip
    unzip -q /tmp/d2j.zip -d "$LAB"
    mv "$LAB/dex-tools-v2.4" "$LAB/dex2jar"
    chmod +x "$LAB/dex2jar"/*.sh
fi

########################################
# 6. FRIDA SERVER
########################################
echo -e "${C}[Section 6] Verifying Frida Binary...${NC}"

if [ -f "$LAB/frida-server" ]; then
    echo -e "${G}[V] Frida-server binary exists.${NC}"
else
    echo -e "${Y}[+] Fetching Frida-server $FRIDA_VER...${NC}"
    FRIDA_FILE="frida-server-$FRIDA_VER-android-x86_64.xz"
    wget -q -O "$LAB/$FRIDA_FILE" "https://github.com/frida/frida/releases/download/$FRIDA_VER/$FRIDA_FILE"
    unxz -f "$LAB/$FRIDA_FILE"
    mv "$LAB/frida-server-$FRIDA_VER-android-x86_64" "$LAB/frida-server"
    chmod +x "$LAB/frida-server"
fi


########################################
# 8. ANDROID STUDIO (KOALA)
########################################
echo -e "${C}[Section 8] Verifying Android Studio Koala...${NC}"

if [ -d "$STUDIO_DIR/bin" ]; then
    echo -e "${G}[V] Android Studio is already installed at $STUDIO_DIR.${NC}"
else
    echo -e "${Y}[+] Downloading Android Studio Koala ($STUDIO_VER)...${NC}"
    wget -q --show-progress -O /tmp/android-studio.tar.gz "$STUDIO_URL"
    
    echo -e "${Y}[+] Extracting to $HOME...${NC}"
    tar -xzf /tmp/android-studio.tar.gz -C "$HOME"
    rm /tmp/android-studio.tar.gz

    # Create Desktop Entry for Kali Applications Menu
    echo -e "${Y}[+] Creating Desktop Entry...${NC}"
    mkdir -p "$HOME/.local/share/applications"
    cat <<EOF > "$HOME/.local/share/applications/android-studio.desktop"
[Desktop Entry]
Version=1.0
Type=Application
Name=Android Studio Koala
Exec="$STUDIO_DIR/bin/studio.sh" %f
Icon=$STUDIO_DIR/bin/studio.png
Categories=Development;IDE;
Terminal=false
StartupNotify=true
EOF
    chmod +x "$HOME/.local/share/applications/android-studio.desktop"
fi

########################################
# 7. ENVIRONMENT (Updated)
########################################
echo -e "${C}[Section 7] Verifying Shell Config...${NC}"

ZSH_CONFIG="$HOME/.zshrc"
if grep -q "Mobile Pentest Lab Path Config" "$ZSH_CONFIG"; then
    echo -e "${G}[V] .zshrc environment already configured.${NC}"
else
    echo -e "${Y}[+] Patching .zshrc...${NC}"
    cat << EOF >> "$ZSH_CONFIG"

# --- Mobile Pentest Lab Path Config ---
export ANDROID_SDK_ROOT="$SDK"
export STUDIO_PATH="$STUDIO_DIR/bin"
export PATH="\$PATH:\$ANDROID_SDK_ROOT/platform-tools"
export PATH="\$PATH:\$ANDROID_SDK_ROOT/emulator"
export PATH="\$PATH:\$ANDROID_SDK_ROOT/cmdline-tools/latest/bin"
export PATH="\$PATH:\$STUDIO_PATH"
export PATH="\$PATH:\$HOME/.local/bin"
# --------------------------------------
EOF
    echo -e "${G}[V] Environment configured. Run 'source ~/.zshrc' to apply changes.${NC}"
fi

echo -e "${G}[!] Setup Complete! Launch Android Studio from your menu or type 'studio.sh'.${NC}"
}

run_start_lab() {
# Ensure SDK paths are set so the script can find 'emulator' and 'adb'
SDK="$HOME/android-sdk"
export ANDROID_SDK_ROOT="$SDK"
export PATH=$PATH:$SDK/platform-tools:$SDK/emulator

echo "[+] Fetching available emulators..."

# Grab the list of AVDs into a bash array
AVD_LIST=($(emulator -list-avds))

# Check if the array is empty
if [ ${#AVD_LIST[@]} -eq 0 ]; then
    echo "[-] No emulators found! Please run the creation scripts first."
    exit 1
fi

echo ""
echo "================================"
echo "      AVAILABLE EMULATORS"
echo "================================"
echo ""

# Loop through the array and print them as numbered options
for i in "${!AVD_LIST[@]}"; do
    # ${!AVD_LIST[@]} gets the indices (0, 1, 2, etc.)
    # We add 1 so the menu starts at 1 instead of 0
    echo "$((i+1))) ${AVD_LIST[$i]}"
done

# Add an exit option at the end
EXIT_OPT=$(( ${#AVD_LIST[@]} + 1 ))
echo "$EXIT_OPT) Exit"
echo ""

read -p "Select an emulator to start: " opt

# Validate that the input is a number and within range
if ! [[ "$opt" =~ ^[0-9]+$ ]] || [ "$opt" -lt 1 ] || [ "$opt" -gt "$EXIT_OPT" ]; then
    echo "[-] Invalid selection."
    exit 1
fi

# Handle exit
if [ "$opt" -eq "$EXIT_OPT" ]; then
    echo "Exiting..."
    exit 0
fi

# Map the user's choice (1-based) back to the array index (0-based)
SELECTED_AVD="${AVD_LIST[$((opt-1))]}"

echo ""
echo "[+] Starting $SELECTED_AVD..."

# Launch the selected emulator
emulator -avd "$SELECTED_AVD" -gpu auto -no-snapshot -no-boot-anim > /dev/null 2>&1 &

echo "[+] Waiting for $SELECTED_AVD to boot..."
adb wait-for-device

until [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" == "1" ]; do
    sleep 2
done

echo "[+] Device booted successfully!"

echo ""
echo "================================================================"
echo "[+] Lab is ready. Happy hunting!"
echo "================================================================"
}

run_create_clean() {
# Exit immediately if a command exits with a non-zero status
set -e 

########################################
# CONFIG & ENV
########################################

SDK="$HOME/android-sdk"
API=31
SYS_IMAGE="system-images;android-$API;google_apis_playstore;x86_64"

export ANDROID_SDK_ROOT="$SDK"
export PATH=$PATH:$SDK/platform-tools:$SDK/emulator:$SDK/cmdline-tools/latest/bin

########################################
# 0. USER INPUT
########################################

echo ""
read -p "Enter a name for your Pixel 6 Pro emulator (e.g., pixel6pro-lab): " AVD

if [ -z "$AVD" ]; then
    echo "[-] Error: Emulator name cannot be empty."
    exit 1
fi

if avdmanager list avd | grep -q "Name: $AVD"; then
    echo "[-] Error: AVD '$AVD' already exists. Choose a different name or delete it first."
    exit 1
fi

########################################
# 1. CHECK & INSTALL SYSTEM IMAGE
########################################

echo "[+] Checking for the Play Store system image..."

if ! sdkmanager --list_installed | grep -q "$SYS_IMAGE"; then
    echo "[!] System image not found. Downloading it now (this may take a minute)..."
    yes | sdkmanager "$SYS_IMAGE" > /dev/null
    echo "[+] Download complete!"
else
    echo "[+] System image already installed."
fi

########################################
# 2. AVD CREATION
########################################

echo "[+] Creating new Pixel 6 Pro AVD '$AVD'..."

echo no | avdmanager create avd \
    -n "$AVD" \
    -k "$SYS_IMAGE" \
    -d pixel_6_pro \
    -f

########################################
# 3. HARDWARE OPTIMIZATION
########################################

echo "[+] Optimizing Pixel 6 Pro hardware settings for maximum performance..."

CONFIG_FILE="$HOME/.android/avd/$AVD.avd/config.ini"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "[-] Error: config.ini was not found. AVD creation may have failed."
    exit 1
fi

# The bulletproof config updater
update_config() {
    # Delete the setting completely (handling any weird spaces or duplicates)
    sed -i -E "/^$1\s*=/d" "$CONFIG_FILE"
    # Append the fresh, correct setting to the bottom
    echo "$1=$2" >> "$CONFIG_FILE"
}

# Pixel 6 Pro Display
update_config "hw.lcd.width" "1440"
update_config "hw.lcd.height" "3120"
update_config "hw.lcd.density" "512"
update_config "skin.dynamic" "yes"

# Extreme Performance Hardware Settings
update_config "hw.keyboard" "yes"
update_config "hw.cpu.ncore" "6"             # 6 CPU cores for heavy multitasking
update_config "hw.ramSize" "8192"            # 8 GB RAM to keep the OS buttery smooth
update_config "vm.heapSize" "1024"           # 1 GB VM Heap to prevent crashes in large apps
update_config "hw.gpu.enabled" "yes"
update_config "hw.gpu.mode" "host"           # Forces the use of the dedicated host GPU (e.g., NVIDIA)
update_config "disk.dataPartition.size" "16G" # Expanded storage for large APKs and caching

########################################
# 4. BOOT SEQUENCE
########################################

echo "[+] Starting Pixel 6 Pro emulator in the background..."

set +e

emulator \
    -avd "$AVD" \
    -gpu host \
    -no-boot-anim \
    -no-snapshot \
    -skin 1440x3120 \
    -scale 0.8 \
    > /dev/null 2>&1 &

echo "[+] Waiting for device to boot..."
adb wait-for-device

until [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" == "1" ]; do
    sleep 2
done

echo ""
echo "================================================================"
echo "[+] Pixel 6 Pro emulator '$AVD' is fully booted and ready!"
echo "[!] Performance Specs: 8 GB RAM, 6 CPU cores, Host GPU Rendering"
echo "================================================================"
}

run_create_root() {
# Exit immediately if a command exits with a non-zero status
set -e

########################################
# CONFIG & ENV
########################################

SDK="$HOME/android-sdk"
LAB="$HOME/mobile-lab"
API=31
SYS_IMAGE="system-images;android-$API;google_apis;x86_64"

export ANDROID_SDK_ROOT="$SDK"
export PATH=$PATH:$SDK/platform-tools:$SDK/emulator:$SDK/cmdline-tools/latest/bin

# The exact path to the ramdisk that needs patching
RAMDISK_PATH="$SDK/system-images/android-$API/google_apis/x86_64/ramdisk.img"

########################################
# 0. USER INPUT
########################################

echo ""
read -p "Enter a name for the new ROOTED emulator (e.g., root-lab-01): " AVD

if [ -z "$AVD" ]; then
    echo "[-] Error: Emulator name cannot be empty."
    exit 1
fi

if avdmanager list avd | grep -q "Name: $AVD"; then
    echo "[-] Error: AVD '$AVD' already exists. Choose a different name or delete it first."
    exit 1
fi

########################################
# 1. CHECK & INSTALL SYSTEM IMAGE
########################################

echo "[+] Checking for the standard Google APIs system image..."

if ! sdkmanager --list_installed | grep -q "$SYS_IMAGE"; then
    echo "[!] System image not found. Downloading it now (this may take a minute)..."
    yes | sdkmanager "$SYS_IMAGE" > /dev/null
    echo "[+] Download complete!"
else
    echo "[+] System image already installed."
fi

########################################
# 2. AVD CREATION
########################################

echo "[+] Creating new rooted Pixel 6 Pro AVD '$AVD'..."

echo no | avdmanager create avd \
    -n "$AVD" \
    -k "$SYS_IMAGE" \
    -d pixel_6_pro \
    -f

########################################
# 3. HARDWARE OPTIMIZATION
########################################

echo "[+] Optimizing hardware settings for Kali Linux VM..."

CONFIG_FILE="$HOME/.android/avd/$AVD.avd/config.ini"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "[-] Error: config.ini was not found. AVD creation may have failed."
    exit 1
fi

update_config() {
    sed -i -E "/^$1\s*=/d" "$CONFIG_FILE"
    echo "$1=$2" >> "$CONFIG_FILE"
}

# 1080p Display Fix for VMware
update_config "hw.lcd.width" "1080"
update_config "hw.lcd.height" "2400"
update_config "hw.lcd.density" "420"
update_config "skin.dynamic" "yes"

# Extreme Performance Hardware Settings
update_config "hw.keyboard" "yes"
update_config "hw.cpu.ncore" "6"
update_config "hw.ramSize" "8192"
update_config "vm.heapSize" "1024"
update_config "hw.gpu.enabled" "yes"
update_config "hw.gpu.mode" "host"
update_config "disk.dataPartition.size" "16G"

########################################
# 4. ROOTAVD SETUP
########################################

if [ ! -d "$LAB/rootAVD" ]; then
    echo "[+] Downloading rootAVD..."
    git clone https://github.com/newbit1/rootAVD.git "$LAB/rootAVD"
fi

########################################
# 5. BOOT & PATCH
########################################

echo "[+] Starting emulator for Magisk patching..."

set +e 

emulator \
    -avd "$AVD" \
    -gpu host \
    -no-snapshot \
    -no-boot-anim \
    > /dev/null 2>&1 &

echo "[+] Waiting for device to boot..."
adb wait-for-device

until [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" == "1" ]; do
    sleep 2
done

set -e

echo "[+] Device booted. Executing rootAVD..."
cd "$LAB/rootAVD"
bash rootAVD.sh "$RAMDISK_PATH"

echo "[+] rootAVD patching complete. The emulator has been shut down."
sleep 3

########################################
# 6. REBOOT ROOTED DEVICE
########################################

echo "[+] Restarting the now-rooted emulator..."

set +e

emulator \
    -avd "$AVD" \
    -gpu host \
    -no-snapshot \
    -no-boot-anim \
    > /dev/null 2>&1 &

adb wait-for-device
until [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" == "1" ]; do
    sleep 2
done

echo "[+] Rooted emulator booted successfully!"

########################################
# FINISH
########################################

echo ""
echo "================================================================"
echo "                 ROOT SETUP COMPLETE!                           "
echo "================================================================"
echo "Action Required Inside the Emulator:"
echo "  1. Open the app drawer and open the 'Magisk' app."
echo "  2. It will say 'Requires Additional Setup'. Click 'OK'."
echo "  3. The emulator will reboot one last time."
echo "================================================================"
}

run_remove_emulator() {
########################################
# CONFIG & ENV
########################################

SDK="$HOME/android-sdk"
export ANDROID_SDK_ROOT="$SDK"
export PATH=$PATH:$SDK/platform-tools:$SDK/emulator:$SDK/cmdline-tools/latest/bin

echo "[+] Fetching available emulators..."

# Grab the list of AVDs into a bash array
AVD_LIST=($(emulator -list-avds 2>/dev/null))

# Check if the array is empty
if [ ${#AVD_LIST[@]} -eq 0 ]; then
    echo "[-] No emulators found on this system."
    exit 0
fi

echo ""
echo "========================================"
echo "       EMULATOR REMOVAL TOOL"
echo "========================================"
echo ""

# Loop through the array and print them as numbered options
for i in "${!AVD_LIST[@]}"; do
    echo "$((i+1))) Delete: ${AVD_LIST[$i]}"
done

# Define the dynamic option numbers for "Delete All" and "Exit"
DELETE_ALL_OPT=$(( ${#AVD_LIST[@]} + 1 ))
EXIT_OPT=$(( ${#AVD_LIST[@]} + 2 ))

echo "----------------------------------------"
echo "$DELETE_ALL_OPT) DELETE ALL EMULATORS"
echo "$EXIT_OPT) Exit"
echo ""

read -p "Select an option: " opt

# Validate input
if ! [[ "$opt" =~ ^[0-9]+$ ]] || [ "$opt" -lt 1 ] || [ "$opt" -gt "$EXIT_OPT" ]; then
    echo "[-] Invalid selection."
    exit 1
fi

# Handle Exit
if [ "$opt" -eq "$EXIT_OPT" ]; then
    echo "Exiting..."
    exit 0
fi

########################################
# EXECUTION LOGIC
########################################

# Handle Delete All
if [ "$opt" -eq "$DELETE_ALL_OPT" ]; then
    echo ""
    echo "WARNING: You are about to delete ALL emulators."
    read -p "Are you absolutely sure? (y/N): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        for avd in "${AVD_LIST[@]}"; do
            echo "[+] Deleting $avd..."
            avdmanager delete avd -n "$avd" | grep -v "Deleted AVD" || true
        done
        echo "[+] All emulators have been removed."
    else
        echo "[-] Aborted."
    fi
    exit 0
fi

# Handle Single Deletion
SELECTED_AVD="${AVD_LIST[$((opt-1))]}"
echo ""
read -p "Are you sure you want to delete '$SELECTED_AVD'? (y/N): " confirm

if [[ "$confirm" =~ ^[Yy]$ ]]; then
    echo "[+] Deleting $SELECTED_AVD..."
    # avdmanager handles the actual deletion of the files and configuration
    avdmanager delete avd -n "$SELECTED_AVD" | grep -v "Deleted AVD" || true
    echo "[+] '$SELECTED_AVD' has been successfully removed."
else
    echo "[-] Aborted."
fi
}

# ==============================================================================
# MAIN SCRIPT EXECUTION (from main.sh)
# ==============================================================================

# --- THEME COLORS ---
G='\033[0;32m'   # Green
BG='\033[1;32m'  # Bold Green
C='\033[0;36m'   # Cyan
R='\033[0;31m'   # Red
Y='\033[1;33m'   # Yellow
NC='\033[0m'     # No Color

# Resolve the directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# ==============================================================================
# HARDWARE VIRTUALIZATION AUDIT
# ==============================================================================
check_hardware() {
    V_CPU_COUNT=$(egrep -c '(vmx|svm)' /proc/cpuinfo)
    
    if [ "$V_CPU_COUNT" -eq 0 ]; then
        IS_SUITABLE=false
        V_CPU_STATUS="${R}NOT SUPPORTED${NC}"
        KVM_STATUS="${R}DISABLED${NC}"
        SUITABILITY="${R}NOT SUITABLE (LOCKED)${NC}"
    else
        IS_SUITABLE=true
        V_CPU_STATUS="${G}SUPPORTED${NC}"
        if [ -e /dev/kvm ]; then
            KVM_STATUS="${G}READY${NC}"
            SUITABILITY="${G}EXCELLENT${NC}"
        else
            KVM_STATUS="${R}MISSING${NC}"
            SUITABILITY="${Y}CONFIG REQUIRED${NC}"
        fi
    fi
}

while true; do
    check_hardware

    clear
    echo -e "${BG}################################################################"
    echo -e "##                                                            ##"
    echo -e "##            ${G}MOBILE PENTEST ENVIRONMENT BUILDER${BG}              ##"
    echo -e "##            ${C}Prompt By: nnrnull${BG}                              ##"
    echo -e "##                                                            ##"
    echo -e "################################################################${NC}"
    
    # --- STATUS DASHBOARD ---
    echo -e "  ${BG}SYSTEM STATUS:${NC}"
    echo -e "  > CPU Virtualization : $V_CPU_STATUS"
    echo -e "  > KVM Acceleration   : $KVM_STATUS"
    echo -e "  > LAB SUITABILITY    : $SUITABILITY"
    echo -e "${BG}----------------------------------------------------------------${NC}"
    echo ""

    # Display options based on suitability
    if [ "$IS_SUITABLE" = true ]; then
        echo -e "  ${G}[${C}1${G}]${NC} > ${BG}DEPLOY${NC}   :: Audit & Install Core Tools"
        echo -e "  ${G}[${C}2${G}]${NC} > ${BG}LAUNCH${NC}   :: Start an Emulator"
        echo -e "  ${G}[${C}3${G}]${NC} > ${BG}CREATE${NC}   :: New Clean Emulator"
        echo -e "  ${G}[${C}4${G}]${NC} > ${BG}ROOT${NC}     :: New Rooted Emulator"
        echo -e "  ${G}[${C}5${G}]${NC} > ${BG}PURGE${NC}    :: Remove Emulator(s)"
    else
        echo -e "  ${R}[X] OPTIONS 1-5 ARE LOCKED DUE TO HARDWARE LIMITATIONS${NC}"
        echo -e "  ${Y}[!] Enable VT-x/AMD-V in your BIOS or VMware Settings.${NC}"
    fi

    echo -e "  ${G}[${C}0${G}]${NC} > ${Y}EXIT${NC}     :: Terminate Session"
    echo ""
    echo -e "${BG}----------------------------------------------------------------${NC}"
    echo -n -e "${G}root@nn4ch1n3${NC}:${C}~${NC}${BG}#${NC} "
    read opt

    # Lock logic: Block options 1-5 if not suitable
    if [ "$IS_SUITABLE" = false ] && [[ "$opt" =~ ^[1-5]$ ]]; then
        echo -e "${R}[!] ACCESS DENIED: Hardware not suitable for emulation.${NC}"
        sleep 2
        continue
    fi

    case $opt in
        1)
            (run_install_tools)
            echo -e "\n${C}>> Press [Enter] to return...${NC}"; read
            ;;
        2)
            (run_start_lab)
            echo -e "\n${C}>> Press [Enter] to return...${NC}"; read
            ;;
        3)
            (run_create_clean)
            echo -e "\n${C}>> Press [Enter] to return...${NC}"; read
            ;;
        4)
            (run_create_root)
            echo -e "\n${C}>> Press [Enter] to return...${NC}"; read
            ;;
        5)
            (run_remove_emulator)
            echo -e "\n${C}>> Press [Enter] to return...${NC}"; read
            ;;
        0)
            echo -e "${Y}[!] System session terminated. Goodbye.${NC}"
            exit 0
            ;;
        *)
            echo -e "${R}[X] Invalid selection.${NC}"
            sleep 1
            ;;
    esac
done
