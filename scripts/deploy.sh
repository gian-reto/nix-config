#!/usr/bin/env -S nix shell nixpkgs#bash nixpkgs#coreutils nixpkgs#gum nixpkgs#nixos-anywhere --command bash
# shellcheck shell=bash
set -euo pipefail
IFS=$'\n\t'

# Create a temporary directory.
TEMP=$(mktemp -d)

# Function to cleanup temporary directory on exit.
cleanup() {
  rm -rf "$TEMP"
}
trap cleanup EXIT

# Load available NixOS configurations from `flake.nix`.
NIXOS_CONFIGURATIONS=$(
  gum spin --spinner dot --title "Evaluating flake..." -- \
  bash -c 'sleep 1; nix eval --json .#nixosConfigurations --apply builtins.attrNames 2>/dev/null | jq -r ".[]"'
)

# Let user choose a configuration to deploy. These correspond to the keys in
# `nixosConfigurations`, and should be the name of the host.
HOST_NAME=$(printf "%s\n" "$NIXOS_CONFIGURATIONS" | gum choose --header "Select config to deploy:")

clear;

# Find corresponding secret for the selected host configuration in 1Password.
OP_ITEMS=$(
  gum spin --spinner dot --title "Fetching secrets from 1Password..." -- \
  bash -c 'op item list --tags nixos-host --format json' _
)
OP_ITEM_ID=$(
  jq -r --arg name "$HOST_NAME" '
    [.[] | select((.title // "" | ascii_downcase) == $name) | .id] | first // empty
  ' <<<"$OP_ITEMS"
)
OP_VAULT_NAME=$(
  jq -r --arg id "$OP_ITEM_ID" '
    first(.[] | select(.id == $id)) | .vault.name
  ' <<<"$OP_ITEMS"
)

if [ -z "${OP_ITEM_ID:-}" ]; then
  gum log --structured --level error "No matching 1Password item found (case-insensitive)." name "$HOST_NAME"
  exit 1
fi
if [ -z "${OP_VAULT_NAME:-}" ]; then
  gum log --structured --level error "Could not determine vault name for 1Password item." id "$OP_ITEM_ID"
  exit 1
fi

# Read the individual components of the `age` key from 1Password.
AGE_CREATED=$(
  # shellcheck disable=SC2016
  gum spin --spinner dot --title "Reading age timestamp..." -- \
  bash -c 'op read "op://$0/$1/age/created"' \
  "$OP_VAULT_NAME" "$OP_ITEM_ID"
)
AGE_PUBLIC_KEY=$(
  # shellcheck disable=SC2016
  gum spin --spinner dot --title "Reading age public key..." -- \
  bash -c 'op read "op://$0/$1/age/public-key"' \
  "$OP_VAULT_NAME" "$OP_ITEM_ID"
)
AGE_SECRET_KEY=$(
  # shellcheck disable=SC2016
  gum spin --spinner dot --title "Reading age secret key..." -- \
  bash -c 'op read "op://$0/$1/age/secret-key"' \
  "$OP_VAULT_NAME" "$OP_ITEM_ID"
)

# Validate that we got all the components we need.
if [ -z "${AGE_CREATED:-}" ] || [ -z "${AGE_PUBLIC_KEY:--}" ] || [ -z "${AGE_SECRET_KEY:-}" ]; then
  gum log --structured --level error "Could not read some age key components from 1Password." id "$OP_ITEM_ID"
  exit 1
fi

# Create the directory where `sops` expects to find the `age` key file.
install -d -m755 "$TEMP/var/lib/sops-nix"

# Write the `age` key file.
printf '# created: %s\n# public key: %s\n%s\n' "$AGE_CREATED" "$AGE_PUBLIC_KEY" "$AGE_SECRET_KEY" > "$TEMP/var/lib/sops-nix/key.txt"

# Set the correct permissions on the `age` key file.
chmod 600 "$TEMP/var/lib/sops-nix/key.txt"

# Display the selected options.
echo "Host name: $HOST_NAME"
echo "Host config: .#$HOST_NAME"
echo "Secret ID: $OP_ITEM_ID"
echo "Temporary directory: $TEMP"
echo

# Ask for confirmation.
PROCEED=$(gum choose "Yes" "No" --header "Proceed with these settings?")
if [ "$PROCEED" = "No" ]; then
  gum log --structured --level info "Deployment cancelled."
  exit 0
fi

clear;

# Ask how to deploy.
DEPLOY_METHOD=$(gum choose "Run in local VM" "Deploy to remote host" --header "Select deployment method:")

clear;

case "$DEPLOY_METHOD" in
  "Run in local VM")
    # Export `VM_AGE_KEY_DIR` which will be used during the Nix build to set the
    # correct mount path for the VM to use.
    export VM_AGE_KEY_DIR="$TEMP/var/lib/sops-nix"

    # shellcheck disable=SC2016
    VM_OUT_PATH=$(
      gum spin --spinner dot --title "Building VM..." -- \
      bash -c 'nix build ".#nixosConfigurations.$0.config.system.build.vm" --no-link --print-out-paths --quiet 2>/dev/null' "$HOST_NAME"
    )

    # Run the VM and trap Ctrl+C.
    gum log --structured --level info "Starting VM" host "$HOST_NAME"
    
    # Start VM with output redirected to a temporary file for monitoring.
    VM_LOG="$TEMP/vm.log"
    "$VM_OUT_PATH/bin/run-$HOST_NAME-vm" > "$VM_LOG" 2>&1 &
    VM_PID=$!

    # shellcheck disable=SC2317 # False positive, as this is used in `trap`.
    stop_vm() {
      gum log --structured --level info "Stopping VM (pid $VM_PID)..."
      kill -TERM "$VM_PID" 2>/dev/null || true
      wait "$VM_PID" 2>/dev/null || true
    }
    trap 'stop_vm; exit 130' INT
    trap 'stop_vm' TERM

    # Show spinner while waiting for VM to boot.
    # shellcheck disable=SC2016
    gum spin --spinner dot --title "Waiting for VM to boot..." -- \
    bash -c '
      while [ ! -f "$1" ] || ! grep -q "login:" "$1" 2>/dev/null; do
        sleep 1
        # Check if VM process is still running.
        if ! kill -0 "$2" 2>/dev/null; then
          gum log --structured --level error "VM process died unexpectedly"
          exit 1
        fi
      done
    ' _ "$VM_LOG" "$VM_PID"

    # VM is ready, show connection info.
    gum log --structured --level info "VM is ready" host "$HOST_NAME"
    gum log --structured --level info "Connect with: ssh root@vm -p 2222"
    gum log --structured --level info "Press Ctrl+C to stop the VM"

    wait "$VM_PID"
    STATUS=$?
    trap - INT TERM
    gum log --structured --level info "VM exited with status $STATUS"
    exit "$STATUS"
    ;;
  "Deploy to remote host")
    # Offer various deployment options.
    OPTION_BUILD_ON_REMOTE=$(gum choose "Yes" "No" --header "Build on remote host?")
    OPTION_DISK_ENCRYPT=$(gum choose "Yes" "No" --header "Copy disk encryption keys (LUKS)?")

    TARGET_HOST="root@$HOST_NAME"

    # Build up nixos-anywhere command dynamically.
    CMD=(nixos-anywhere)

    # Add disk encryption keys for copying if requested.
    if [ "$OPTION_DISK_ENCRYPT" = "Yes" ]; then
      CMD+=(--disk-encryption-keys /tmp/secret.key <(op read op://Development/3x3x7fbtnr74l65fjtakpznuui/password))
    fi

    # Generate hardware config if the `hardware-configuration.nix` file does not exist yet.
    HARDWARE_CONFIG_FILE="./hosts/$HOST_NAME/hardware-configuration.nix"
    if [ ! -f "$HARDWARE_CONFIG_FILE" ]; then
      # Instruct nixos-anywhere to generate hardware config into the repository path.
      CMD+=(--generate-hardware-config nixos-generate-config "$HARDWARE_CONFIG_FILE")
    fi

    if [ "$OPTION_BUILD_ON_REMOTE" = "Yes" ]; then
      CMD+=(--build-on-remote)
    fi

    # Copy age key directory so sops-nix can decrypt secrets on first boot.
    CMD+=(--extra-files "$TEMP")

    # Base flake and target host flags.
    CMD+=(--flake ".#$HOST_NAME" --target-host "$TARGET_HOST")

    echo "Command to be executed:"
    printf '%q ' "${CMD[@]}"
    echo

    CONFIRM_DEPLOYMENT=$(gum choose "Yes" "No" --header "Proceed with remote deployment?")
    if [ "$CONFIRM_DEPLOYMENT" = "No" ]; then
      gum log --structured --level info "Remote deployment cancelled."
      exit 0
    fi

    gum log --structured --level info "Starting remote deployment..." host "$HOST_NAME" target "$TARGET_HOST"
    if ! "${CMD[@]}"; then
      STATUS=$?
      gum log --structured --level error "Remote deployment failed." code "$STATUS"
      exit "$STATUS"
    fi

    gum log --structured --level info "Remote deployment completed successfully." host "$HOST_NAME"
    ;;
esac
