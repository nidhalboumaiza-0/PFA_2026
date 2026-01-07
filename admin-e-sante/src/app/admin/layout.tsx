'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { useTheme } from 'next-themes';
import { useAuth } from '@/components/providers/auth-provider';
import { useSocket } from '@/components/providers/socket-provider';
import { useToast } from '@/hooks/use-toast';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Sheet, SheetContent, SheetTrigger } from '@/components/ui/sheet';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import { Avatar, AvatarFallback } from '@/components/ui/avatar';
import { Badge } from '@/components/ui/badge';
import { Separator } from '@/components/ui/separator';
import {
  LayoutDashboard,
  Users,
  UserCheck,
  Calendar,
  FileText,
  ClipboardList,
  Bell,
  Activity,
  MessageSquare,
  Settings,
  LogOut,
  Search,
  Sun,
  Moon,
  Menu,
  Heart,
  ShieldAlert,
} from 'lucide-react';
import { notificationsService, dashboardService } from '@/lib/api';
import { NotificationBell } from '@/components/notification-bell';
import { ConnectionIndicator } from '@/components/connection-indicator';
import { NavLink } from '@/components/ui/nav-link';

const navigation = [
  { name: 'Dashboard', href: '/admin', icon: LayoutDashboard },
  { name: 'Users', href: '/admin/users', icon: Users },
  { name: 'Doctor Verification', href: '/admin/doctors', icon: UserCheck },
  { name: 'Appointments', href: '/admin/appointments', icon: Calendar },
  { name: 'Reviews', href: '/admin/reviews', icon: MessageSquare },
  { name: 'Audit Logs', href: '/admin/audit-logs', icon: ClipboardList },
  { name: 'Notifications', href: '/admin/notifications', icon: Bell },
  { name: 'Medical Records', href: '/admin/medical-records', icon: FileText },
  { name: 'Messaging', href: '/admin/messaging', icon: MessageSquare },
  { name: 'Platform Health', href: '/admin/health', icon: ShieldAlert },
  { name: 'Settings', href: '/admin/settings', icon: Settings },
];

export default function AdminLayout({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const router = useRouter();
  const { theme, setTheme } = useTheme();
  const { user, logout, isLoading, isAuthenticated } = useAuth();
  const { notificationSocket, userSocket, isConnected } = useSocket();
  const { toast } = useToast();
  const [unreadCount, setUnreadCount] = useState(0);
  const [pendingVerifications, setPendingVerifications] = useState(0);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  // Redirect to login if not authenticated
  useEffect(() => {
    if (!isLoading && !isAuthenticated) {
      router.push('/login');
    }
  }, [isLoading, isAuthenticated, router]);

  useEffect(() => {
    // Only fetch data when authenticated
    if (!isAuthenticated) return;
    
    fetchUnreadCount();
    fetchPendingVerifications();

    if (notificationSocket) {
      notificationSocket.on('new_notification', (notification) => {
        setUnreadCount((prev) => prev + 1);
        toast({
          title: notification.title,
          description: notification.body,
        });
      });

      notificationSocket.on('admin_alert', (alert) => {
        setUnreadCount((prev) => prev + 1);
        toast({
          title: alert.title,
          description: alert.body,
          variant: 'destructive',
        });
      });

      return () => {
        notificationSocket.off('new_notification');
        notificationSocket.off('admin_alert');
      };
    }

    if (userSocket) {
      userSocket.on('doctor_verified', () => {
        toast({
          title: 'Doctor Verified',
          description: 'A doctor has been verified successfully',
        });
        fetchPendingVerifications();
      });

      return () => {
        userSocket.off('doctor_verified');
      };
    }
  }, [isAuthenticated, notificationSocket, userSocket]);

  const fetchUnreadCount = async () => {
    try {
      const response = await notificationsService.getUnreadCount();
      setUnreadCount(response.unreadCount);
    } catch (error) {
      console.error('Failed to fetch unread count:', error);
    }
  };

  const fetchPendingVerifications = async () => {
    try {
      const stats = await dashboardService.getQuickStats();
      setPendingVerifications(stats.pendingVerifications);
    } catch (error) {
      console.error('Failed to fetch pending verifications:', error);
    }
  };

  const handleLogout = async () => {
    await logout();
  };

  const NavItems = () => (
    <>
      {navigation.map((item) => {
        const isActive = pathname === item.href;
        const showBadge = item.name === 'Notifications' && unreadCount > 0;
        const showPendingBadge = item.name === 'Users' && pendingVerifications > 0;

        return (
          <NavLink
            key={item.name}
            href={item.href}
            onClick={() => setMobileMenuOpen(false)}
            className={`flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-all ${
              isActive
                ? 'bg-blue-600 text-white'
                : 'text-muted-foreground hover:bg-accent hover:text-accent-foreground'
            }`}
          >
            <item.icon className="h-5 w-5" />
            <span className="flex-1">{item.name}</span>
            {showBadge && (
              <Badge variant="destructive" className="text-xs">
                {unreadCount}
              </Badge>
            )}
            {showPendingBadge && (
              <Badge variant="secondary" className="text-xs">
                {pendingVerifications}
              </Badge>
            )}
          </NavLink>
        );
      })}
    </>
  );

  // Show loading state while checking auth
  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-background">
        <div className="flex flex-col items-center gap-4">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
          <p className="text-muted-foreground">Loading...</p>
        </div>
      </div>
    );
  }

  // Don't render admin UI if not authenticated
  if (!isAuthenticated) {
    return null;
  }

  return (
    <div className="min-h-screen bg-background">
      {/* Mobile Header */}
      <header className="lg:hidden sticky top-0 z-50 border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
        <div className="flex h-14 items-center gap-4 px-4">
          <Sheet open={mobileMenuOpen} onOpenChange={setMobileMenuOpen}>
            <SheetTrigger asChild>
              <Button variant="ghost" size="icon">
                <Menu className="h-5 w-5" />
              </Button>
            </SheetTrigger>
            <SheetContent side="left" className="w-72 p-0">
              <div className="flex h-full flex-col">
                <div className="flex items-center gap-3 p-6 border-b">
                  <div className="flex items-center justify-center w-10 h-10 bg-blue-600 rounded-full">
                    <Heart className="w-5 h-5 text-white" />
                  </div>
                  <div>
                    <h1 className="font-bold text-lg">E-Santé</h1>
                    <p className="text-xs text-muted-foreground">Admin Dashboard</p>
                  </div>
                </div>
                <nav className="flex-1 p-4 space-y-1 overflow-y-auto">
                  <NavItems />
                </nav>
                <div className="p-4 border-t">
                  <Button
                    variant="outline"
                    className="w-full justify-start"
                    onClick={handleLogout}
                  >
                    <LogOut className="mr-2 h-4 w-4" />
                    Logout
                  </Button>
                </div>
              </div>
            </SheetContent>
          </Sheet>
          <div className="flex items-center gap-2">
            <Heart className="h-5 w-5 text-blue-600" />
            <span className="font-semibold">E-Santé Admin</span>
          </div>
          <div className="ml-auto flex items-center gap-2">
            <Button
              variant="ghost"
              size="icon"
              onClick={() => setTheme(theme === 'dark' ? 'light' : 'dark')}
            >
              <Sun className="h-5 w-5 rotate-0 scale-100 transition-all dark:-rotate-90 dark:scale-0" />
              <Moon className="absolute h-5 w-5 rotate-90 scale-0 transition-all dark:rotate-0 dark:scale-100" />
            </Button>
          </div>
        </div>
      </header>

      <div className="flex">
        {/* Sidebar - Desktop */}
        <aside className="hidden lg:flex flex-col w-72 min-h-screen border-r bg-card">
          <div className="flex items-center gap-3 p-6 border-b">
            <div className="flex items-center justify-center w-10 h-10 bg-blue-600 rounded-full">
              <Heart className="w-5 h-5 text-white" />
            </div>
            <div>
              <h1 className="font-bold text-lg">E-Santé</h1>
              <p className="text-xs text-muted-foreground">Admin Dashboard</p>
            </div>
          </div>

          <nav className="flex-1 p-4 space-y-1 overflow-y-auto">
            <NavItems />
          </nav>

          <div className="p-4 border-t space-y-2">
            <DropdownMenu>
              <DropdownMenuTrigger asChild>
                <Button variant="ghost" className="w-full justify-start gap-3">
                  <Avatar className="h-8 w-8">
                    <AvatarFallback className="bg-blue-600 text-white">
                      {user?.profile?.firstName?.charAt(0) || 'A'}
                    </AvatarFallback>
                  </Avatar>
                  <div className="flex flex-col items-start text-left">
                    <span className="text-sm font-medium">
                      {user?.profile?.firstName} {user?.profile?.lastName}
                    </span>
                    <span className="text-xs text-muted-foreground capitalize">
                      {user?.role}
                    </span>
                  </div>
                </Button>
              </DropdownMenuTrigger>
              <DropdownMenuContent align="end" className="w-56">
                <DropdownMenuLabel>
                  <div className="flex flex-col space-y-1">
                    <p className="text-sm font-medium">
                      {user?.profile?.firstName} {user?.profile?.lastName}
                    </p>
                    <p className="text-xs text-muted-foreground">{user?.email}</p>
                  </div>
                </DropdownMenuLabel>
                <DropdownMenuSeparator />
                <DropdownMenuItem onClick={handleLogout}>
                  <LogOut className="mr-2 h-4 w-4" />
                  Logout
                </DropdownMenuItem>
              </DropdownMenuContent>
            </DropdownMenu>
          </div>
        </aside>

        {/* Main Content */}
        <main className="flex-1 min-h-screen">
          {/* Desktop Header */}
          <header className="hidden lg:flex sticky top-0 z-40 border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60 h-16 items-center gap-4 px-6">
            <div className="flex items-center gap-2 flex-1 max-w-md">
              <Search className="h-4 w-4 text-muted-foreground" />
              <Input
                type="search"
                placeholder="Search users, appointments..."
                className="h-9 w-full"
              />
            </div>

            <div className="flex items-center gap-2">
              <ConnectionIndicator />
              <Button
                variant="ghost"
                size="icon"
                onClick={() => setTheme(theme === 'dark' ? 'light' : 'dark')}
              >
                <Sun className="h-5 w-5 rotate-0 scale-100 transition-all dark:-rotate-90 dark:scale-0" />
                <Moon className="absolute h-5 w-5 rotate-90 scale-0 transition-all dark:rotate-0 dark:scale-100" />
              </Button>

              <Separator orientation="vertical" className="h-6" />

              <NotificationBell />

              <DropdownMenu>
                <DropdownMenuTrigger asChild>
                  <Button variant="ghost" className="gap-2">
                    <Avatar className="h-8 w-8">
                      <AvatarFallback className="bg-blue-600 text-white">
                        {user?.profile?.firstName?.charAt(0) || 'A'}
                      </AvatarFallback>
                    </Avatar>
                    <span className="text-sm font-medium hidden md:inline-block">
                      {user?.profile?.firstName} {user?.profile?.lastName}
                    </span>
                  </Button>
                </DropdownMenuTrigger>
                <DropdownMenuContent align="end" className="w-56">
                  <DropdownMenuLabel>
                    <div className="flex flex-col space-y-1">
                      <p className="text-sm font-medium">
                        {user?.profile?.firstName} {user?.profile?.lastName}
                      </p>
                      <p className="text-xs text-muted-foreground">{user?.email}</p>
                    </div>
                  </DropdownMenuLabel>
                  <DropdownMenuSeparator />
                  <DropdownMenuItem onClick={handleLogout}>
                    <LogOut className="mr-2 h-4 w-4" />
                    Logout
                  </DropdownMenuItem>
                </DropdownMenuContent>
              </DropdownMenu>
            </div>
          </header>

          {/* Page Content */}
          <div className="p-4 lg:p-6">{children}</div>
        </main>
      </div>
    </div>
  );
}
