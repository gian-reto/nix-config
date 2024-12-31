import NM from "gi://NM?version=1.0";

export const getIconNameForDeviceType = (deviceType: NM.DeviceType): string => {
  switch (deviceType) {
    case NM.DeviceType.ETHERNET:
      return "network-wired-symbolic";

    case NM.DeviceType.WIFI:
      return "network-wireless-symbolic";

    case NM.DeviceType.TUN:
    case NM.DeviceType.WIREGUARD:
      return "network-vpn-symbolic";

    case NM.DeviceType.MODEM:
      // TODO: Return correct icon for the current ModemManager
      // connection type. Probably queryable from DBus (see:
      // https://github.com/System64fumo/sysbar/blob/main/src/modules/cellular.cpp).
      return "network-cellular-connected-symbolic";

    default:
      // Just return the wired icon for all other device types.
      return "network-wired-symbolic";
  }
};

export const getLabelForDeviceType = (deviceType: NM.DeviceType): string => {
  switch (deviceType) {
    case NM.DeviceType.ETHERNET:
      return "Ethernet";

    case NM.DeviceType.WIFI:
      return "Wi-Fi";

    case NM.DeviceType.TUN:
    case NM.DeviceType.WIREGUARD:
      return "VPN";

    case NM.DeviceType.MODEM:
      return "Cellular";

    default:
      return "Unknown";
  }
};
