'use client';

import { useEffect, useState } from 'react';
import { usePathname } from 'next/navigation';

// Simple global trigger
let triggerStart: (() => void) | null = null;

export function startNavigation() {
  triggerStart?.();
}

export function TopLoader() {
  const pathname = usePathname();
  const [show, setShow] = useState(false);
  const [width, setWidth] = useState(0);

  useEffect(() => {
    triggerStart = () => {
      setShow(true);
      setWidth(30);
    };
    return () => { triggerStart = null; };
  }, []);

  // When pathname changes, complete the bar quickly
  useEffect(() => {
    if (show) {
      setWidth(100);
      const t = setTimeout(() => {
        setShow(false);
        setWidth(0);
      }, 150);
      return () => clearTimeout(t);
    }
  }, [pathname]);

  // Animate while loading
  useEffect(() => {
    if (!show || width >= 90) return;
    const t = setTimeout(() => setWidth(w => Math.min(w + 15, 90)), 100);
    return () => clearTimeout(t);
  }, [show, width]);

  if (!show) return null;

  return (
    <div className="fixed top-0 left-0 right-0 z-[100] h-0.5">
      <div
        className="h-full bg-blue-600 transition-all duration-100"
        style={{ width: `${width}%` }}
      />
    </div>
  );
}
