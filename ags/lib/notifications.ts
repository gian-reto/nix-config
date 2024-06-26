const notifications = await Service.import("notifications");

const blacklist: Array<string> = [];

export const initNotificationService = () => {
  // Show notifications for 24 hours if not dismissed manually.
  notifications.popupTimeout = 1000 * 60 * 60 * 24;
  notifications.forceTimeout = true;
  notifications.cacheActions = false;
  notifications.clearDelay = 1000;

  const notify = notifications.constructor.prototype.Notify.bind(notifications);

  notifications.constructor.prototype.Notify = (
    appName: string,
    ...rest: unknown[]
  ) => {
    if (blacklist.includes(appName)) return Number.MAX_SAFE_INTEGER;

    return notify(appName, ...rest);
  };
};
