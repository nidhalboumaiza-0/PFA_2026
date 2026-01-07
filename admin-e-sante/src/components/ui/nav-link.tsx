'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { ReactNode } from 'react';

interface NavLinkProps {
  href: string;
  children: ReactNode;
  className?: string;
  onClick?: () => void;
}

export function NavLink({ href, children, className, onClick }: NavLinkProps) {
  const pathname = usePathname();
  
  const handleClick = () => {
    onClick?.();
  };

  return (
    <Link 
      href={href}
      onClick={handleClick}
      className={className}
    >
      {children}
    </Link>
  );
}
