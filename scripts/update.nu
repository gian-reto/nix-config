#!/usr/bin/env -S nix shell nixpkgs#nushell nixpkgs#unzip --command nu --no-config-file

const repository_root_path = path self ..
const helium_directory_path = $repository_root_path | path join modules features helium
const extensions_lock_file_path = $helium_directory_path | path join extensions.lock.json
const systems = [[name, arch, os_arch, nacl_arch]; ['aarch64-linux', 'arm64', 'aarch64', 'aarch64'], ['x86_64-linux', 'x64', 'x86_64', 'x86-64']]

def fetch-helium-extension-details [system: record<name: string, arch: string, os_arch: string, nacl_arch: string>, extension_id: string, product_version: string]: nothing -> record<id: string, version: string, url: string, hash: string> {
    let request_parameters = {
        response: 'redirect'
        os: 'linux'
        arch: $system.arch
        os_arch: $system.os_arch
        nacl_arch: $system.nacl_arch
        prod: 'chromiumcrx'
        prodchannel: 'stable'
        prodversion: $product_version
        acceptformat: 'crx3'
        x: $'id=($extension_id)&installsource=ondemand&uc'
    }
    let request_url = $request_parameters | url build-query | $'https://clients2.google.com/service/update2/crx?($in)'
    let response = http get --allow-errors --full --raw --redirect-mode manual $request_url
    if $response.status != 302 {
        error make $'Chrome Web Store returned HTTP ($response.status) for ($extension_id) on ($system.name).'
    }

    # Extract the stable download URL for the CRX file at the current extension version.
    let url = $response.headers.response | where name == 'location' | get value.0

    # Download the CRX file into a temporary directory and extract the version and hash.
    let temp_directory_path = mktemp --directory
    let crx_file_path = $temp_directory_path | path join $'($system.name)-($extension_id).crx'
    let crx_file = http get --raw $url

    $crx_file | save --raw $crx_file_path

    # CRX headers make unzip return 1 after successfully extracting the manifest.
    let version = ^unzip -p $crx_file_path manifest.json | complete | get stdout | from json | get version
    let digest = $crx_file | hash sha256 --binary | encode base64

    # Cleanup the temporary directory.
    rm --recursive $temp_directory_path

    {
        id: $extension_id
        version: $version
        url: $url
        hash: $'sha256-($digest)'
    }
}

def update-helium-extensions [] {
    let extensions_file = open ($helium_directory_path | path join extensions.json)
    let flake_lock_file = open --raw ($repository_root_path | path join flake.lock) | from json
    let source = $flake_lock_file.nodes | get nixpkgs-helium | get locked
    let product_version = $'https://raw.githubusercontent.com/($source.owner)/($source.repo)/($source.rev)/pkgs/applications/networking/browsers/chromium/info.json'
    | http get $in
    | get helium.version

    print $'Updating Helium extensions for version ($product_version).'

    let json = $systems
    | par-each --keep-order {|system|
            $extensions_file
            | par-each --keep-order {|extension_id|
                fetch-helium-extension-details $system $extension_id $product_version
            }
            | collect {|extensions| [$system.name $extensions]}
        }
    | into record
    | to json --indent 2

    # Override JSON lock file with updated extension details.
    $"($json)\n" | save --force $extensions_lock_file_path

    print $'Updated Helium extensions lock file at ($extensions_lock_file_path).'
}

def main [--all] {
    let updates = ['Helium Extensions']
    let selected = if $all { $updates } else {
        $updates | input list --multi 'Select updates:'
    }

    if 'Helium Extensions' in $selected {
        update-helium-extensions
    }
}
