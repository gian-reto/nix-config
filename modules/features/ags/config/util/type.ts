export type MapKey<TMap> = TMap extends Map<infer TKey, any> ? TKey : never;
export type MapValue<TMap> = TMap extends Map<any, infer TValue>
  ? TValue
  : never;
