# NixOS module for AMD RDNA4 gfx1201 GPUs, e.g. Radeon AI PRO R9700.
# Most settings taken from: https://github.com/tenarches/nix-rdna4.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.features.gfx1201;
in {
  options.features.gfx1201 = {
    enable = lib.mkOption {
      description = ''
        Whether to enable support for AMD RDNA4 gfx1201 GPUs.
      '';
      type = lib.types.bool;
      default = false;
      example = true;
    };

    lact.configFile = lib.mkOption {
      description = ''
        Path to a LACT configuration file to install as /etc/lact/config.yaml.
      '';
      type = lib.types.nullOr lib.types.path;
      default = null;
      example = lib.literalExpression "./lact.yaml";
    };
  };

  config.os = lib.mkIf cfg.enable {
    # amdgpu.gpu_recovery=1: Enable soft GPU reset on driver timeout instead of hard hang.
    # Critical for compute workloads (LLM inference) that push the memory subsystem.
    #
    # amdgpu.lockup_timeout=10000: 10-second lockup threshold. ROCm kernels can
    # legitimately run for several seconds without yielding; the default 5s causes false
    # resets.
    #
    # iommu=pt: IOMMU passthrough mode. Reduces DMA translation overhead, improves GPU
    # memory latency. Standard practice for any AMD GPU compute host.
    boot.kernelParams = [
      "amdgpu.gpu_recovery=1"
      "amdgpu.lockup_timeout=10000"
      "iommu=pt"
    ];

    services.xserver.videoDrivers = ["amdgpu"];

    hardware = {
      graphics = {
        enable = true;
        enable32Bit = true; # Required for Wine, Steam, 32-bit Vulkan clients.

        extraPackages = with pkgs; [
          # VA-API for RDNA4's dedicated multimedia engine (AV1, H.265 decode/encode).
          libva
          # OpenCL ICD via ROCm CLR. Makes the GPU visible to clinfo and OpenCL
          # applications. This is the dispatch layer; the full ROCm compute stack
          # lives in rdna4-rocm.nix.
          rocmPackages.clr.icd
        ];

        extraPackages32 = with pkgs.pkgsi686Linux; [
          libva
        ];
      };

      amdgpu = {
        # Load amdgpu in initrd for early KMS, a stable splash, and render node
        # availability before userspace services start.
        initrd.enable = true;
        opencl.enable = true;
        # Enable OverDrive for manual GPU tweaking.
        overdrive.enable = true;
      };
    };

    services = {
      # Enable LACT for performance tweaking.
      lact.enable = true;

      # KFD device permissions.
      #
      # `/dev/kfd` is the HSA compute interface, owned by `root:render` by default.
      # Users need both `video` and `render` groups.
      udev.extraRules = ''
        SUBSYSTEM=="drm", KERNEL=="renderD*", GROUP="render", MODE="0660"
        KERNEL=="kfd", GROUP="render", MODE="0660"
      '';
    };

    environment = {
      etc."lact/config.yaml" = lib.mkIf (cfg.lact.configFile != null) {
        source = cfg.lact.configFile;
      };

      # Environment variables for AMD GPU compute workloads.
      #
      # Note: `HSA_OVERRIDE_GFX_VERSION` is intentionally absent. `gfx1201` is officially
      # supported in ROCm 7.x. Setting the override misidentifies the ISA at the HSA
      # runtime level and causes wrong code generation.
      sessionVariables = {
        # Explicit GPU target for tools that JIT-compile HIP kernels at runtime.
        HCC_AMDGPU_TARGET = "gfx1201";
        LIBVA_DRIVER_NAME = "radeonsi";
        # Limit ROCm device visibility. "0" = first GPU.
        ROCR_VISIBLE_DEVICES = "0";
        VDPAU_DRIVER = "radeonsi";
      };

      systemPackages = with pkgs; [
        amdgpu_top # Detailed AMDGPU metrics: clocks, VRAM, power, engines.
        clinfo # Verify OpenCL ICD is visible.
        lm_sensors # `sensors` CLI for temperatures and fan speeds.
        mesa-demos
        nvtopPackages.amd # Real-time GPU utilization (replaces `nvtopPackages.nvidia`).
        pciutils # `lspci` for PCI device inspection.
        rocmPackages.rocminfo # Enumerate HSA agents; verify `gfx1201` is visible.
        rocmPackages.rocm-smi # GPU power, temperature, clock states.
        vulkan-tools # `vulkaninfo`, `vkcube`, etc.
        vulkan-validation-layers
      ];
    };

    # Provide the conventional ROCm path (`/opt/rocm` symlink) for tools that do not know
    # about Nix store paths.
    #
    # AMD's toolchain and most ML frameworks hard-code `/opt/rocm` for library discovery.
    # This is a NixOS workaround; add paths here as required for different workloads
    # (e.g. rocSPARSE, MIOpen).
    systemd.tmpfiles.rules = let
      rocmPath = pkgs.symlinkJoin {
        name = "rocm-gfx1201";
        paths = with pkgs.rocmPackages; [
          clr # HSA runtime, HIP runtime, OpenCL ICD, device libs.
          hipblas # HIP BLAS API over rocBLAS.
          rocblas # BLAS kernels (critical path for LLM matrix ops).
          rocminfo # `rocminfo` binary.
          rocm-smi # System Management Interface.
        ];
      };
    in [
      "L+ /opt/rocm - - - - ${rocmPath}"
    ];
  };
}
