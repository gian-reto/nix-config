{ 
  config, 
  lib, 
  modulesPath, 
  ... 
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot = {
    initrd = {
      includeDefaultModules = false;
      availableKernelModules = [
        "nvme"
        "phy_qcom_qmp_pcie"
        # "pcie_qcom"
        "i2c_hid_of"
        "i2c_qcom_geni"
        "leds_qcom_lpg"
        "pwm_bl"
        "qrtr"
        "pmic_glink_altmode"
        "gpio_sbu_mux"
        "phy_qcom_qmp_combo"
        "panel-edp"
        "msm"
        "phy_qcom_edp"
      ];
      kernelModules = [ ];
    };
    kernelModules = [ ];
    extraModulePackages = [ ];
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/6c199b72-4a82-4bc6-9ab2-e5a0d32f04de";
      fsType = "ext4";
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/6492-704B";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };
  };

  swapDevices = [
    {
      device = "/dev/disk/by-uuid/f2a6dd2e-f82f-47ea-b4b4-b129ea2574e7";
    }
  ];

  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform.system = "aarch64-linux";
}