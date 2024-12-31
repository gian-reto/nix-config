import { type Subscribable } from "astal/binding";
import { Gtk } from "astal/gtk4";

export class VariableMap<K, T extends Gtk.Widget = Gtk.Widget>
  implements Subscribable<[K, T][]>
{
  private subscriptions = new Set<(v: Array<[K, T]>) => void>();
  private map: Map<K, T> = new Map();

  constructor(initial?: Iterable<[K, T]>) {
    this.map = new Map(initial);
  }

  private _notifiy(): void {
    const value = this.get();
    for (const subscription of this.subscriptions) {
      subscription(value);
    }
  }

  private _delete(key: K): boolean {
    const value = this.map.get(key);

    if (value instanceof Gtk.Widget) {
      value.emit("destroy");
    }

    return this.map.delete(key);
  }

  set(key: K, value: T): boolean {
    const result = this._delete(key);
    this.map.set(key, value);
    this._notifiy();

    return result;
  }

  delete(key: K): boolean {
    const result = this._delete(key);
    this._notifiy();

    return result;
  }

  get(): [K, T][] {
    return [...this.map.entries()];
  }

  subscribe(callback: (v: Array<[K, T]>) => void): () => void {
    this.subscriptions.add(callback);

    return () => this.subscriptions.delete(callback);
  }
}
