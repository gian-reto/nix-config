/*
 * Powermenu Service.
 * Source: https://github.com/Aylur/dotfiles/blob/main/ags/service/powermenu.ts.
 */

const CMD = {
  sleep: "systemctl suspend",
  reboot: "systemctl reboot",
  logout: "pkill Hyprland",
  shutdown: "shutdown now",
};

export type Action = "sleep" | "reboot" | "logout" | "shutdown";

class PowerMenu extends Service {
  static {
    Service.register(
      this,
      {},
      {
        title: ["string"],
        cmd: ["string"],
      }
    );
  }

  #title = "";
  #cmd = "";

  get title() {
    return this.#title;
  }

  action(action: Action) {
    [this.#cmd, this.#title] = {
      sleep: [CMD.sleep, "Sleep"],
      reboot: [CMD.reboot, "Reboot"],
      logout: [CMD.logout, "Log Out"],
      shutdown: [CMD.shutdown, "Shutdown"],
    }[action];

    this.notify("cmd");
    this.notify("title");
    this.emit("changed");
    App.closeWindow("powermenu");
    App.openWindow("verification");
  }

  readonly shutdown = () => {
    this.action("shutdown");
  };

  readonly exec = () => {
    App.closeWindow("verification");
    Utils.exec(this.#cmd);
  };
}

const powermenu = new PowerMenu();
Object.assign(globalThis, { powermenu });
export default powermenu;
