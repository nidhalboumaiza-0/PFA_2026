'use client';

import { useEffect, useState } from 'react';
import { Bell } from 'lucide-react';
import { useSocket } from '@/components/providers/socket-provider';
import { notificationsService } from '@/lib/api';
import { toast } from '@/hooks/use-toast';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/components/providers/auth-provider';

export function NotificationBell() {
  const [unreadCount, setUnreadCount] = useState(0);
  const { notificationSocket } = useSocket();
  const { isAuthenticated, isLoading } = useAuth();
  const router = useRouter();

  // Fetch initial count - only when authenticated
  useEffect(() => {
    if (!isLoading && isAuthenticated) {
      fetchUnreadCount();
    }
  }, [isLoading, isAuthenticated]);

  // Real-time updates
  useEffect(() => {
    if (!notificationSocket) return;

    const handleNewNotification = (notification: any) => {
      setUnreadCount((prev) => prev + 1);
      toast({
        title: notification.title,
        description: notification.body,
      });
    };

    const handleAdminAlert = (alert: any) => {
      setUnreadCount((prev) => prev + 1);
      toast({
        title: alert.title,
        description: alert.body,
        variant: 'destructive',
      });
    };

    notificationSocket.on('new_notification', handleNewNotification);
    notificationSocket.on('admin_alert', handleAdminAlert);

    return () => {
      notificationSocket.off('new_notification');
      notificationSocket.off('admin_alert');
    };
  }, [notificationSocket]);

  const fetchUnreadCount = async () => {
    try {
      const response = await notificationsService.getUnreadCount();
      setUnreadCount(response.unreadCount);
    } catch (error) {
      console.error('Failed to fetch unread count:', error);
    }
  };

  const handleClick = () => {
    router.push('/admin/notifications');
  };

  return (
    <button
      onClick={handleClick}
      className="relative p-2 hover:bg-accent rounded-md transition-colors"
      aria-label="Notifications"
    >
      <Bell className="h-5 w-5" />
      {unreadCount > 0 && (
        <span className="absolute -top-1 -right-1 bg-red-500 text-white text-xs rounded-full h-5 w-5 flex items-center justify-center font-semibold">
          {unreadCount > 99 ? '99+' : unreadCount}
        </span>
      )}
    </button>
  );
}
