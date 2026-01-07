// Simple in-memory cache with TTL for API responses

interface CacheEntry<T> {
  data: T;
  timestamp: number;
  ttl: number;
}

class ApiCache {
  private cache = new Map<string, CacheEntry<any>>();
  private defaultTTL = 30000; // 30 seconds default

  set<T>(key: string, data: T, ttl?: number): void {
    this.cache.set(key, {
      data,
      timestamp: Date.now(),
      ttl: ttl ?? this.defaultTTL,
    });
  }

  get<T>(key: string): T | null {
    const entry = this.cache.get(key);
    if (!entry) return null;

    const isExpired = Date.now() - entry.timestamp > entry.ttl;
    if (isExpired) {
      this.cache.delete(key);
      return null;
    }

    return entry.data as T;
  }

  has(key: string): boolean {
    return this.get(key) !== null;
  }

  invalidate(key: string): void {
    this.cache.delete(key);
  }

  invalidatePattern(pattern: string): void {
    const regex = new RegExp(pattern);
    for (const key of this.cache.keys()) {
      if (regex.test(key)) {
        this.cache.delete(key);
      }
    }
  }

  clear(): void {
    this.cache.clear();
  }

  // Get or fetch - returns cached data or fetches new data
  async getOrFetch<T>(
    key: string,
    fetcher: () => Promise<T>,
    ttl?: number
  ): Promise<T> {
    const cached = this.get<T>(key);
    if (cached !== null) {
      return cached;
    }

    const data = await fetcher();
    this.set(key, data, ttl);
    return data;
  }
}

// Singleton instance
export const apiCache = new ApiCache();

// Cache keys
export const CACHE_KEYS = {
  DASHBOARD_STATS: 'dashboard:stats',
  DASHBOARD_HEALTH: 'dashboard:health',
  USERS_LIST: (page: number, role: string, status: string, search: string) =>
    `users:list:${page}:${role}:${status}:${search}`,
  APPOINTMENTS_LIST: (page: number, status: string, search: string) =>
    `appointments:list:${page}:${status}:${search}`,
  REVIEWS_LIST: (page: number) => `reviews:list:${page}`,
  NOTIFICATIONS_LIST: (page: number) => `notifications:list:${page}`,
  AUDIT_LOGS: (page: number) => `audit:logs:${page}`,
  REFERRALS_LIST: (page: number) => `referrals:list:${page}`,
};

// TTL constants (in ms)
export const CACHE_TTL = {
  SHORT: 15000,    // 15 seconds - for frequently changing data
  MEDIUM: 30000,   // 30 seconds - default
  LONG: 60000,     // 1 minute - for rarely changing data
  VERY_LONG: 300000, // 5 minutes - for static data
};
