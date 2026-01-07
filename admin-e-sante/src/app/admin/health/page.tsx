'use client';

import { useEffect, useState } from 'react';
import { useAuth } from '@/components/providers/auth-provider';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Activity, CheckCircle, XCircle, AlertTriangle, Server } from 'lucide-react';
import { dashboardService } from '@/lib/api';
import type { PlatformHealth } from '@/lib/api';
import { toast } from '@/hooks/use-toast';
import { Skeleton } from '@/components/ui/skeleton';

export default function PlatformHealthPage() {
  const [health, setHealth] = useState<PlatformHealth | null>(null);
  const [loading, setLoading] = useState(true);
  const { isAuthenticated, isLoading: authLoading } = useAuth();

  useEffect(() => {
    // Only fetch when authenticated
    if (!authLoading && isAuthenticated) {
      fetchHealth();
      const interval = setInterval(fetchHealth, 30000); // Refresh every 30 seconds
      return () => clearInterval(interval);
    }
  }, [authLoading, isAuthenticated]);

  const fetchHealth = async () => {
    try {
      setLoading(true);
      const data = await dashboardService.getHealth();
      setHealth(data);
    } catch (error: any) {
      toast({
        title: 'Error',
        description: error.message || 'Failed to fetch health status',
        variant: 'destructive',
      });
    } finally {
      setLoading(false);
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'healthy':
        return <CheckCircle className="h-5 w-5 text-green-600" />;
      case 'degraded':
        return <AlertTriangle className="h-5 w-5 text-yellow-600" />;
      case 'unhealthy':
        return <XCircle className="h-5 w-5 text-red-600" />;
      default:
        return <Activity className="h-5 w-5 text-gray-600" />;
    }
  };

  const getStatusBadge = (status: string) => {
    const colors: Record<string, string> = {
      healthy: 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200',
      degraded: 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200',
      unhealthy: 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200',
    };
    return (
      <Badge className={colors[status] || 'bg-gray-100 text-gray-800'}>
        {status.toUpperCase()}
      </Badge>
    );
  };

  const getResponseTimeColor = (time: number) => {
    if (time < 100) return 'text-green-600';
    if (time < 300) return 'text-yellow-600';
    return 'text-red-600';
  };

  if (loading) {
    return (
      <div className="space-y-6">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Platform Health</h1>
          <p className="text-muted-foreground">Real-time service monitoring</p>
        </div>
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
          {[1, 2, 3, 4, 5, 6, 7].map((i) => (
            <Card key={i}>
              <CardHeader>
                <Skeleton className="h-6 w-32" />
                <Skeleton className="h-4 w-24" />
              </CardHeader>
              <CardContent>
                <Skeleton className="h-4 w-20" />
              </CardContent>
            </Card>
          ))}
        </div>
      </div>
    );
  }

  const serviceNames: Record<string, string> = {
    'auth-service': 'Authentication Service',
    'user-service': 'User Service',
    'rdv-service': 'Appointment Service',
    'notification-service': 'Notification Service',
    'messaging-service': 'Messaging Service',
    'medical-records-service': 'Medical Records Service',
    'audit-service': 'Audit Service',
  };

  const overallServices = health?.services ? Object.entries(health.services) : [];

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-3xl font-bold tracking-tight">Platform Health</h1>
        <p className="text-muted-foreground">
          Real-time monitoring of all platform services
        </p>
      </div>

      {/* Overall Status */}
      <Card className={health?.overall === 'unhealthy' ? 'border-red-200 dark:border-red-900' : ''}>
        <CardHeader>
          <div className="flex items-center justify-between">
            <div>
              <CardTitle className="flex items-center gap-2">
                <Server className="h-5 w-5" />
                Overall Platform Status
              </CardTitle>
              <CardDescription>
                Aggregated health status across all services
              </CardDescription>
            </div>
            <div className="flex items-center gap-3">
              {getStatusIcon(health?.overall || 'unknown')}
              {getStatusBadge(health?.overall || 'unknown')}
            </div>
          </div>
        </CardHeader>
      </Card>

      {/* Services Grid */}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
        {overallServices.map(([serviceName, service]) => (
          <Card
            key={serviceName}
            className={
              service.status === 'unhealthy'
                ? 'border-red-200 dark:border-red-900'
                : service.status === 'degraded'
                ? 'border-yellow-200 dark:border-yellow-900'
                : ''
            }
          >
            <CardHeader>
              <div className="flex items-start justify-between">
                <div className="space-y-1">
                  <CardTitle className="text-base">
                    {serviceNames[serviceName] || serviceName}
                  </CardTitle>
                  <CardDescription>
                    {serviceName.replace('-', ' ').replace('_', ' ')}
                  </CardDescription>
                </div>
                <div className="flex flex-col items-end gap-2">
                  {getStatusIcon(service.status)}
                  {getStatusBadge(service.status)}
                </div>
              </div>
            </CardHeader>
            <CardContent>
              <div className="flex items-center justify-between">
                <span className="text-sm text-muted-foreground">Response Time</span>
                <span className={`font-semibold ${getResponseTimeColor(service.responseTime)}`}>
                  {service.responseTime}ms
                </span>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      {/* Stats */}
      <div className="grid gap-4 md:grid-cols-3">
        <Card>
          <CardHeader className="pb-2">
            <CardDescription>Healthy Services</CardDescription>
            <CardTitle className="text-2xl text-green-600">
              {
                overallServices.filter(([_, s]) => s.status === 'healthy').length
              }
            </CardTitle>
          </CardHeader>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardDescription>Degraded Services</CardDescription>
            <CardTitle className="text-2xl text-yellow-600">
              {
                overallServices.filter(([_, s]) => s.status === 'degraded').length
              }
            </CardTitle>
          </CardHeader>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardDescription>Unhealthy Services</CardDescription>
            <CardTitle className="text-2xl text-red-600">
              {
                overallServices.filter(([_, s]) => s.status === 'unhealthy').length
              }
            </CardTitle>
          </CardHeader>
        </Card>
      </div>

      {/* Legend */}
      <Card>
        <CardHeader>
          <CardTitle>Status Legend</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex flex-wrap gap-6">
            <div className="flex items-center gap-2">
              <CheckCircle className="h-5 w-5 text-green-600" />
              <div>
                <p className="font-medium text-sm">Healthy</p>
                <p className="text-xs text-muted-foreground">Service operating normally</p>
              </div>
            </div>
            <div className="flex items-center gap-2">
              <AlertTriangle className="h-5 w-5 text-yellow-600" />
              <div>
                <p className="font-medium text-sm">Degraded</p>
                <p className="text-xs text-muted-foreground">Service slow but operational</p>
              </div>
            </div>
            <div className="flex items-center gap-2">
              <XCircle className="h-5 w-5 text-red-600" />
              <div>
                <p className="font-medium text-sm">Unhealthy</p>
                <p className="text-xs text-muted-foreground">Service not responding</p>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
