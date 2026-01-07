'use client';

import { useEffect, useState } from 'react';
import { useAuth } from '@/components/providers/auth-provider';
import { useRealtimeStats } from '@/hooks/useRealtimeStats';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Badge } from '@/components/ui/badge';
import { Progress } from '@/components/ui/progress';
import { Button } from '@/components/ui/button';
import {
  Users,
  UserCheck,
  Calendar,
  MessageSquare,
  Bell,
  ShieldAlert,
  Activity,
  Heart,
  CheckCircle,
  XCircle,
  TrendingUp,
  Server,
  AlertTriangle,
  Zap,
  RefreshCw,
  ArrowUpRight,
  ArrowDownRight,
} from 'lucide-react';
import {
  LineChart,
  Line,
  PieChart,
  Pie,
  Cell,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
  AreaChart,
  Area,
  RadialBarChart,
  RadialBar,
} from 'recharts';
import { dashboardService } from '@/lib/api';
import { Skeleton } from '@/components/ui/skeleton';
import Link from 'next/link';

// Color palette
const COLORS = ['#3b82f6', '#22c55e', '#f59e0b', '#ef4444', '#8b5cf6', '#06b6d4', '#ec4899', '#84cc16'];
const STATUS_COLORS: Record<string, string> = {
  pending: '#f59e0b',
  confirmed: '#3b82f6',
  completed: '#22c55e',
  cancelled: '#ef4444',
  scheduled: '#8b5cf6',
};

interface ServiceHealthData {
  name: string;
  status: 'healthy' | 'degraded' | 'unhealthy';
  latency?: number;
  error?: string;
  lastChecked: string;
}

interface HealthResponse {
  overallStatus: string;
  healthyServices: number;
  totalServices: number;
  services: ServiceHealthData[];
  checkedAt: string;
}

export default function DashboardPage() {
  const { stats, loading } = useRealtimeStats();
  const { isAuthenticated, isLoading: authLoading } = useAuth();
  const [health, setHealth] = useState<HealthResponse | null>(null);
  const [healthLoading, setHealthLoading] = useState(false);

  useEffect(() => {
    if (!authLoading && isAuthenticated) {
      fetchHealth();
      const interval = setInterval(fetchHealth, 30000);
      return () => clearInterval(interval);
    }
  }, [authLoading, isAuthenticated]);

  const fetchHealth = async () => {
    try {
      setHealthLoading(true);
      const healthData = await dashboardService.getHealth();
      setHealth(healthData as any);
    } catch (error) {
      console.error('Failed to fetch health:', error);
    } finally {
      setHealthLoading(false);
    }
  };

  // Prepare chart data - filter out zero values to prevent label overlap
  const appointmentStatusData = stats?.appointments.byStatus
    ? Object.entries(stats.appointments.byStatus)
        .map(([key, value]) => ({
          name: key.charAt(0).toUpperCase() + key.slice(1),
          value: value as number,
          fill: STATUS_COLORS[key] || '#8884d8',
        }))
        .filter(item => item.value > 0) // Remove zero values
    : [];

  const specialtyData = stats?.users.specialtyDistribution?.map((item, index) => ({
    name: item._id || item.specialty || 'Not Specified',
    value: item.count,
    fill: COLORS[index % COLORS.length],
  })).filter(item => item.name && item.name !== 'null' && item.name !== 'undefined' && item.value > 0) || [];

  const busiestHoursData = stats?.appointments.busiestHours?.map((item: any) => ({
    hour: item.time || item.hour || 'N/A',
    appointments: item.count,
  })) || [];

  // Process appointment trend data from backend (last 30 days)
  const appointmentTrendData = (() => {
    const trends = stats?.trends?.appointments || [];
    if (trends.length === 0) {
      // Fallback: generate based on weekly data
      return [
        { date: 'Week 1', appointments: stats?.appointments.thisWeek || 0 },
        { date: 'Week 2', appointments: Math.round((stats?.appointments.thisMonth || 0) * 0.3) },
        { date: 'Week 3', appointments: Math.round((stats?.appointments.thisMonth || 0) * 0.25) },
        { date: 'Week 4', appointments: Math.round((stats?.appointments.thisMonth || 0) * 0.2) },
      ];
    }
    // Get last 14 days for better visualization
    return trends.slice(-14).map((item) => ({
      date: new Date(item._id).toLocaleDateString('en-US', { month: 'short', day: 'numeric' }),
      appointments: item.total,
      completed: item.statuses?.find((s: any) => s.status === 'completed')?.count || 0,
      cancelled: item.statuses?.find((s: any) => s.status === 'cancelled')?.count || 0,
    }));
  })();

  // Process user registration trend data
  const userTrendData = (() => {
    const doctorTrends = stats?.trends?.userRegistrations?.doctors || [];
    const patientTrends = stats?.trends?.userRegistrations?.patients || [];
    
    if (doctorTrends.length === 0 && patientTrends.length === 0) {
      // Fallback data based on registration stats
      const today = stats?.users.newRegistrations.today.total || 0;
      const week = stats?.users.newRegistrations.thisWeek.total || 0;
      const month = stats?.users.newRegistrations.thisMonth.total || 0;
      return [
        { period: 'Today', users: today },
        { period: 'This Week', users: week },
        { period: 'This Month', users: month },
      ];
    }
    
    // Combine doctor and patient trends by date
    const trendMap = new Map<string, { doctors: number; patients: number }>();
    doctorTrends.forEach((item: any) => {
      trendMap.set(item._id, { doctors: item.count, patients: 0 });
    });
    patientTrends.forEach((item: any) => {
      const existing = trendMap.get(item._id) || { doctors: 0, patients: 0 };
      existing.patients = item.count;
      trendMap.set(item._id, existing);
    });
    
    return Array.from(trendMap.entries())
      .sort((a, b) => a[0].localeCompare(b[0]))
      .slice(-14)
      .map(([date, data]) => ({
        date: new Date(date).toLocaleDateString('en-US', { month: 'short', day: 'numeric' }),
        doctors: data.doctors,
        patients: data.patients,
        total: data.doctors + data.patients,
      }));
  })();

  // User distribution data
  const userDistribution = [
    { name: 'Patients', value: stats?.overview.totalPatients || 0, fill: '#3b82f6' },
    { name: 'Doctors', value: stats?.overview.totalDoctors || 0, fill: '#22c55e' },
    { name: 'Admins', value: Math.max(1, (stats?.overview.totalUsers || 0) - (stats?.overview.totalPatients || 0) - (stats?.overview.totalDoctors || 0)), fill: '#f59e0b' },
  ];

  // Completion rate for radial chart
  const completionRate = parseFloat(stats?.appointments.completionRate?.replace('%', '') || '0');
  const completionData = [
    { name: 'Completion Rate', value: completionRate, fill: '#22c55e' },
  ];

  // Performance metrics
  const performanceMetrics = [
    { 
      label: 'Verified Doctors', 
      value: stats?.users.doctors.verified || 0,
      total: stats?.users.doctors.total || 1,
      color: '#22c55e'
    },
    { 
      label: 'Active Users', 
      value: (stats?.users.doctors.active || 0) + (stats?.users.patients.active || 0),
      total: stats?.overview.totalUsers || 1,
      color: '#3b82f6'
    },
    { 
      label: 'Notification Delivery', 
      value: parseInt(stats?.notifications.deliveryRate?.replace('%', '') || '0'),
      total: 100,
      color: '#f59e0b'
    },
  ];

  if (loading) {
    return <DashboardSkeleton />;
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Dashboard</h1>
          <p className="text-muted-foreground">
            Welcome back! Here's what's happening on your platform.
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Badge
            variant={health?.overallStatus === 'healthy' ? 'default' : health?.overallStatus === 'degraded' ? 'secondary' : 'destructive'}
            className="gap-2 px-3 py-1"
          >
            {health?.overallStatus === 'healthy' ? (
              <CheckCircle className="h-4 w-4" />
            ) : health?.overallStatus === 'degraded' ? (
              <AlertTriangle className="h-4 w-4" />
            ) : (
              <XCircle className="h-4 w-4" />
            )}
            Platform {health?.overallStatus || 'Loading...'}
          </Badge>
          <Button variant="outline" size="sm" onClick={fetchHealth} disabled={healthLoading}>
            <RefreshCw className={`h-4 w-4 mr-1 ${healthLoading ? 'animate-spin' : ''}`} />
            Refresh
          </Button>
        </div>
      </div>

      {/* Quick Stats Row */}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        <StatCard
          title="Total Users"
          value={stats?.overview.totalUsers || 0}
          change={stats?.users.newRegistrations.thisMonth.total || 0}
          changeLabel="this month"
          icon={Users}
          iconColor="text-blue-600"
          bgColor="bg-blue-50 dark:bg-blue-950"
          trend="up"
        />
        <StatCard
          title="Doctors"
          value={stats?.overview.totalDoctors || 0}
          change={stats?.users.doctors.active || 0}
          changeLabel="active"
          icon={UserCheck}
          iconColor="text-green-600"
          bgColor="bg-green-50 dark:bg-green-950"
          trend="up"
        />
        <StatCard
          title="Patients"
          value={stats?.overview.totalPatients || 0}
          change={stats?.users.patients.active || 0}
          changeLabel="active"
          icon={Heart}
          iconColor="text-pink-600"
          bgColor="bg-pink-50 dark:bg-pink-950"
          trend="up"
        />
        <StatCard
          title="Today's Appointments"
          value={stats?.appointments.today.total || 0}
          change={stats?.appointments.today.upcoming || 0}
          changeLabel="upcoming"
          icon={Calendar}
          iconColor="text-purple-600"
          bgColor="bg-purple-50 dark:bg-purple-950"
        />
      </div>

      {/* Secondary Stats */}
      <div className="grid gap-4 md:grid-cols-3">
        <StatCard
          title="Messages"
          value={stats?.overview.totalMessages || 0}
          change={stats?.messaging.activeConversations || 0}
          changeLabel="active chats"
          icon={MessageSquare}
          iconColor="text-cyan-600"
          bgColor="bg-cyan-50 dark:bg-cyan-950"
        />
        <StatCard
          title="Notifications"
          value={stats?.overview.totalNotifications || 0}
          change={stats?.notifications.deliveryRate || '0%'}
          changeLabel="delivery rate"
          icon={Bell}
          iconColor="text-orange-600"
          bgColor="bg-orange-50 dark:bg-orange-950"
        />
        <StatCard
          title="Pending Verifications"
          value={stats?.users.doctors.pendingVerification || 0}
          change={0}
          changeLabel="needs attention"
          icon={ShieldAlert}
          iconColor="text-red-600"
          bgColor="bg-red-50 dark:bg-red-950"
          alert={(stats?.users.doctors.pendingVerification || 0) > 0}
        />
      </div>

      {/* Charts Section */}
      <Tabs defaultValue="overview" className="space-y-4">
        <TabsList className="grid w-full max-w-2xl grid-cols-4">
          <TabsTrigger value="overview">Overview</TabsTrigger>
          <TabsTrigger value="appointments">Appointments</TabsTrigger>
          <TabsTrigger value="users">Users</TabsTrigger>
          <TabsTrigger value="performance">Performance</TabsTrigger>
        </TabsList>

        {/* Overview Tab */}
        <TabsContent value="overview" className="space-y-4">
          <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
            {/* Appointment Trend - Area Chart */}
            <Card className="col-span-2">
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <TrendingUp className="h-5 w-5 text-blue-600" />
                  Appointment Trends
                </CardTitle>
                <CardDescription>Appointments over the last 14 days (from backend data)</CardDescription>
              </CardHeader>
              <CardContent>
                {appointmentTrendData.length > 0 ? (
                  <ResponsiveContainer width="100%" height={300}>
                    <AreaChart data={appointmentTrendData}>
                      <defs>
                        <linearGradient id="colorAppointments" x1="0" y1="0" x2="0" y2="1">
                          <stop offset="5%" stopColor="#3b82f6" stopOpacity={0.3}/>
                          <stop offset="95%" stopColor="#3b82f6" stopOpacity={0}/>
                        </linearGradient>
                        <linearGradient id="colorCompleted" x1="0" y1="0" x2="0" y2="1">
                          <stop offset="5%" stopColor="#22c55e" stopOpacity={0.3}/>
                          <stop offset="95%" stopColor="#22c55e" stopOpacity={0}/>
                        </linearGradient>
                        <linearGradient id="colorCancelled" x1="0" y1="0" x2="0" y2="1">
                          <stop offset="5%" stopColor="#ef4444" stopOpacity={0.3}/>
                          <stop offset="95%" stopColor="#ef4444" stopOpacity={0}/>
                        </linearGradient>
                      </defs>
                      <CartesianGrid strokeDasharray="3 3" className="stroke-muted" />
                      <XAxis dataKey="date" className="text-xs" />
                      <YAxis className="text-xs" />
                      <Tooltip 
                        contentStyle={{ 
                          backgroundColor: 'hsl(var(--card))', 
                          border: '1px solid hsl(var(--border))',
                          borderRadius: '8px'
                        }}
                      />
                      <Legend />
                      <Area type="monotone" dataKey="appointments" name="Total" stroke="#3b82f6" fillOpacity={1} fill="url(#colorAppointments)" />
                      <Area type="monotone" dataKey="completed" name="Completed" stroke="#22c55e" fillOpacity={1} fill="url(#colorCompleted)" />
                      <Area type="monotone" dataKey="cancelled" name="Cancelled" stroke="#ef4444" fillOpacity={1} fill="url(#colorCancelled)" />
                    </AreaChart>
                  </ResponsiveContainer>
                ) : (
                  <div className="h-[300px] flex items-center justify-center text-muted-foreground">
                    No trend data available yet
                  </div>
                )}
              </CardContent>
            </Card>

            {/* Completion Rate - Radial Chart */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <CheckCircle className="h-5 w-5 text-green-600" />
                  Completion Rate
                </CardTitle>
                <CardDescription>Appointment completion percentage</CardDescription>
              </CardHeader>
              <CardContent className="flex flex-col items-center justify-center">
                <ResponsiveContainer width="100%" height={200}>
                  <RadialBarChart 
                    cx="50%" 
                    cy="50%" 
                    innerRadius="60%" 
                    outerRadius="100%" 
                    data={completionData} 
                    startAngle={180} 
                    endAngle={0}
                  >
                    <RadialBar
                      background={{ fill: 'hsl(var(--muted))' }}
                      dataKey="value"
                      cornerRadius={10}
                    />
                  </RadialBarChart>
                </ResponsiveContainer>
                <div className="text-center -mt-16">
                  <p className="text-4xl font-bold">{completionRate}%</p>
                  <p className="text-sm text-muted-foreground">completed</p>
                </div>
              </CardContent>
            </Card>
          </div>

          {/* Quick Metrics */}
          <div className="grid gap-4 md:grid-cols-4">
            <QuickMetricCard
              title="This Week"
              value={stats?.appointments.thisWeek || 0}
              label="appointments"
              icon={Calendar}
              color="blue"
            />
            <QuickMetricCard
              title="This Month"
              value={stats?.appointments.thisMonth || 0}
              label="appointments"
              icon={Calendar}
              color="green"
            />
            <QuickMetricCard
              title="New This Week"
              value={stats?.users.newRegistrations.thisWeek.total || 0}
              label="registrations"
              icon={Users}
              color="purple"
            />
            <QuickMetricCard
              title="Active Convos"
              value={stats?.messaging.activeConversations || 0}
              label="conversations"
              icon={MessageSquare}
              color="orange"
            />
          </div>
        </TabsContent>

        {/* Appointments Tab */}
        <TabsContent value="appointments" className="space-y-4">
          <div className="grid gap-4 md:grid-cols-2">
            {/* Appointment Status - Pie Chart */}
            <Card>
              <CardHeader>
                <CardTitle>Status Distribution</CardTitle>
                <CardDescription>Current appointment status breakdown</CardDescription>
              </CardHeader>
              <CardContent>
                <ResponsiveContainer width="100%" height={300}>
                  <PieChart>
                    <Pie
                      data={appointmentStatusData}
                      cx="50%"
                      cy="50%"
                      labelLine={true}
                      label={({ name, percent }) => percent > 0.05 ? `${name} ${(percent * 100).toFixed(0)}%` : ''}
                      outerRadius={80}
                      innerRadius={50}
                      paddingAngle={3}
                      dataKey="value"
                    >
                      {appointmentStatusData.map((entry, index) => (
                        <Cell key={`cell-${index}`} fill={entry.fill} />
                      ))}
                    </Pie>
                    <Tooltip formatter={(value: number) => [value, 'Count']} />
                    <Legend />
                  </PieChart>
                </ResponsiveContainer>
              </CardContent>
            </Card>

            {/* Busiest Hours - Bar Chart */}
            <Card>
              <CardHeader>
                <CardTitle>Busiest Hours</CardTitle>
                <CardDescription>Peak appointment hours during the day</CardDescription>
              </CardHeader>
              <CardContent>
                <ResponsiveContainer width="100%" height={300}>
                  <BarChart data={busiestHoursData}>
                    <CartesianGrid strokeDasharray="3 3" className="stroke-muted" />
                    <XAxis dataKey="hour" className="text-xs" tick={{ fill: 'hsl(var(--foreground))' }} />
                    <YAxis className="text-xs" tick={{ fill: 'hsl(var(--foreground))' }} allowDecimals={false} />
                    <Tooltip 
                      cursor={{ fill: 'hsl(var(--muted))', opacity: 0.3 }}
                      contentStyle={{ 
                        backgroundColor: 'hsl(var(--popover))', 
                        border: '1px solid hsl(var(--border))',
                        borderRadius: '8px',
                        boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1)',
                        padding: '8px 12px',
                        color: 'hsl(var(--popover-foreground))'
                      }}
                      labelStyle={{ fontWeight: 'bold', marginBottom: '4px' }}
                      formatter={(value: number) => [`${value} appointments`, 'Count']}
                      labelFormatter={(label) => `Time: ${label}`}
                    />
                    <Bar dataKey="appointments" fill="#3b82f6" radius={[4, 4, 0, 0]} />
                  </BarChart>
                </ResponsiveContainer>
              </CardContent>
            </Card>

            {/* Top Doctors - Horizontal Bar */}
            <Card className="col-span-2">
              <CardHeader className="flex flex-row items-center justify-between">
                <div>
                  <CardTitle>Top Performing Doctors</CardTitle>
                  <CardDescription>Doctors with most appointments</CardDescription>
                </div>
                <Link href="/admin/appointments/analytics">
                  <Button variant="outline" size="sm">
                    View Analytics
                    <ArrowUpRight className="ml-1 h-4 w-4" />
                  </Button>
                </Link>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  {stats?.appointments.topDoctors?.slice(0, 5).map((doctor, index) => (
                    <div key={doctor.doctorId} className="flex items-center gap-4">
                      <div className="flex items-center justify-center w-8 h-8 rounded-full bg-blue-100 dark:bg-blue-900 text-blue-600 font-bold text-sm">
                        {index + 1}
                      </div>
                      <div className="flex-1">
                        <p className="font-medium text-sm">{doctor.name}</p>
                        <Progress value={(doctor.count / (stats?.appointments.topDoctors?.[0]?.count || 1)) * 100} className="h-2 mt-1" />
                      </div>
                      <Badge variant="secondary">{doctor.count} appointments</Badge>
                    </div>
                  )) || (
                    <p className="text-muted-foreground text-center py-8">No data available</p>
                  )}
                </div>
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        {/* Users Tab */}
        <TabsContent value="users" className="space-y-4">
          <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
            {/* User Distribution - Donut */}
            <Card>
              <CardHeader>
                <CardTitle>User Distribution</CardTitle>
                <CardDescription>Breakdown by user type</CardDescription>
              </CardHeader>
              <CardContent>
                <ResponsiveContainer width="100%" height={250}>
                  <PieChart>
                    <Pie
                      data={userDistribution}
                      cx="50%"
                      cy="50%"
                      innerRadius={50}
                      outerRadius={80}
                      paddingAngle={3}
                      dataKey="value"
                      label={({ name, value }) => `${name}: ${value}`}
                    >
                      {userDistribution.map((entry, index) => (
                        <Cell key={`cell-${index}`} fill={entry.fill} />
                      ))}
                    </Pie>
                    <Tooltip />
                  </PieChart>
                </ResponsiveContainer>
              </CardContent>
            </Card>

            {/* Doctor Specialties - Bar Chart */}
            <Card className="col-span-2">
              <CardHeader>
                <CardTitle>Doctor Specialties</CardTitle>
                <CardDescription>Distribution of doctors by specialty</CardDescription>
              </CardHeader>
              <CardContent>
                <ResponsiveContainer width="100%" height={250}>
                  <BarChart data={specialtyData} layout="vertical">
                    <CartesianGrid strokeDasharray="3 3" className="stroke-muted" />
                    <XAxis type="number" className="text-xs" />
                    <YAxis dataKey="name" type="category" width={100} className="text-xs" />
                    <Tooltip 
                      contentStyle={{ 
                        backgroundColor: 'hsl(var(--card))', 
                        border: '1px solid hsl(var(--border))',
                        borderRadius: '8px'
                      }}
                    />
                    <Bar dataKey="value" radius={[0, 4, 4, 0]}>
                      {specialtyData.map((entry, index) => (
                        <Cell key={`cell-${index}`} fill={entry.fill} />
                      ))}
                    </Bar>
                  </BarChart>
                </ResponsiveContainer>
              </CardContent>
            </Card>

            {/* Registration Stats */}
            <Card className="col-span-3">
              <CardHeader>
                <CardTitle>Registration Statistics</CardTitle>
                <CardDescription>New user registrations over time</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="grid grid-cols-3 gap-4">
                  <div className="text-center p-4 bg-muted rounded-lg">
                    <p className="text-3xl font-bold text-blue-600">{stats?.users.newRegistrations.today.total || 0}</p>
                    <p className="text-sm text-muted-foreground">Today</p>
                  </div>
                  <div className="text-center p-4 bg-muted rounded-lg">
                    <p className="text-3xl font-bold text-green-600">{stats?.users.newRegistrations.thisWeek.total || 0}</p>
                    <p className="text-sm text-muted-foreground">This Week</p>
                  </div>
                  <div className="text-center p-4 bg-muted rounded-lg">
                    <p className="text-3xl font-bold text-purple-600">{stats?.users.newRegistrations.thisMonth.total || 0}</p>
                    <p className="text-sm text-muted-foreground">This Month</p>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        {/* Performance Tab */}
        <TabsContent value="performance" className="space-y-4">
          <div className="grid gap-4 md:grid-cols-2">
            {/* Performance Metrics */}
            <Card>
              <CardHeader>
                <CardTitle>Platform Metrics</CardTitle>
                <CardDescription>Key performance indicators</CardDescription>
              </CardHeader>
              <CardContent className="space-y-6">
                {performanceMetrics.map((metric, index) => (
                  <div key={index} className="space-y-2">
                    <div className="flex justify-between text-sm">
                      <span>{metric.label}</span>
                      <span className="font-medium">{metric.value} / {metric.total}</span>
                    </div>
                    <Progress 
                      value={(metric.value / metric.total) * 100} 
                      className="h-2"
                    />
                  </div>
                ))}
              </CardContent>
            </Card>

            {/* Real-time Stats */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Zap className="h-5 w-5 text-yellow-500" />
                  Real-time Statistics
                </CardTitle>
                <CardDescription>Live platform metrics</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="grid grid-cols-2 gap-4">
                  <div className="p-4 bg-blue-50 dark:bg-blue-950 rounded-lg text-center">
                    <Activity className="h-6 w-6 mx-auto mb-2 text-blue-600" />
                    <p className="text-2xl font-bold">{stats?.overview.totalAppointments || 0}</p>
                    <p className="text-xs text-muted-foreground">Total Appointments</p>
                  </div>
                  <div className="p-4 bg-green-50 dark:bg-green-950 rounded-lg text-center">
                    <MessageSquare className="h-6 w-6 mx-auto mb-2 text-green-600" />
                    <p className="text-2xl font-bold">{stats?.messaging.totalConversations || 0}</p>
                    <p className="text-xs text-muted-foreground">Conversations</p>
                  </div>
                  <div className="p-4 bg-purple-50 dark:bg-purple-950 rounded-lg text-center">
                    <UserCheck className="h-6 w-6 mx-auto mb-2 text-purple-600" />
                    <p className="text-2xl font-bold">{stats?.users.doctors.verified || 0}</p>
                    <p className="text-xs text-muted-foreground">Verified Doctors</p>
                  </div>
                  <div className="p-4 bg-orange-50 dark:bg-orange-950 rounded-lg text-center">
                    <Bell className="h-6 w-6 mx-auto mb-2 text-orange-600" />
                    <p className="text-2xl font-bold">{stats?.notifications.unreadAlerts || 0}</p>
                    <p className="text-xs text-muted-foreground">Unread Alerts</p>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>
        </TabsContent>
      </Tabs>

      {/* Service Health Section */}
      <Card>
        <CardHeader className="flex flex-row items-center justify-between">
          <div>
            <CardTitle className="flex items-center gap-2">
              <Server className="h-5 w-5" />
              Service Health Monitor
            </CardTitle>
            <CardDescription>
              Real-time status of all microservices • {health?.healthyServices || 0}/{health?.totalServices || 0} services healthy
            </CardDescription>
          </div>
          <Link href="/admin/health">
            <Button variant="outline" size="sm">
              View Details
              <ArrowUpRight className="ml-1 h-4 w-4" />
            </Button>
          </Link>
        </CardHeader>
        <CardContent>
          <div className="grid gap-3 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-5">
            {health?.services?.map((service) => (
              <ServiceHealthCard key={service.name} service={service} />
            )) || (
              <>
                {['user-service', 'rdv-service', 'messaging-service', 'notification-service', 'medical-records-service'].map((name) => (
                  <div key={name} className="p-4 border rounded-lg animate-pulse">
                    <Skeleton className="h-5 w-5 mx-auto mb-2" />
                    <Skeleton className="h-4 w-24 mx-auto mb-1" />
                    <Skeleton className="h-3 w-16 mx-auto" />
                  </div>
                ))}
              </>
            )}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

// Service Health Card Component
function ServiceHealthCard({ service }: { service: ServiceHealthData }) {
  const serviceDisplayNames: Record<string, string> = {
    'user-service': 'User Service',
    'rdv-service': 'Appointments',
    'messaging-service': 'Messaging',
    'notification-service': 'Notifications',
    'medical-records-service': 'Medical Records',
    'auth-service': 'Authentication',
    'audit-service': 'Audit Logs',
    'referral-service': 'Referrals',
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'healthy': return 'bg-green-100 dark:bg-green-900 border-green-200 dark:border-green-800';
      case 'degraded': return 'bg-yellow-100 dark:bg-yellow-900 border-yellow-200 dark:border-yellow-800';
      default: return 'bg-red-100 dark:bg-red-900 border-red-200 dark:border-red-800';
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'healthy': return <CheckCircle className="h-5 w-5 text-green-600" />;
      case 'degraded': return <AlertTriangle className="h-5 w-5 text-yellow-600" />;
      default: return <XCircle className="h-5 w-5 text-red-600" />;
    }
  };

  const getLatencyColor = (latency?: number) => {
    if (!latency) return 'text-muted-foreground';
    if (latency < 100) return 'text-green-600';
    if (latency < 300) return 'text-yellow-600';
    return 'text-red-600';
  };

  return (
    <div className={`p-4 border rounded-lg text-center transition-all hover:shadow-md ${getStatusColor(service.status)}`}>
      <div className="flex justify-center mb-2">
        {getStatusIcon(service.status)}
      </div>
      <p className="font-medium text-sm truncate">
        {serviceDisplayNames[service.name] || service.name}
      </p>
      {service.latency !== undefined ? (
        <p className={`text-xs ${getLatencyColor(service.latency)}`}>
          {service.latency}ms
        </p>
      ) : service.error ? (
        <p className="text-xs text-red-600 truncate" title={service.error}>
          Error
        </p>
      ) : (
        <p className="text-xs text-muted-foreground">-</p>
      )}
      <Badge 
        variant={service.status === 'healthy' ? 'default' : service.status === 'degraded' ? 'secondary' : 'destructive'}
        className="mt-2 text-xs"
      >
        {service.status}
      </Badge>
    </div>
  );
}

// Stat Card Component
function StatCard({
  title,
  value,
  change,
  changeLabel,
  icon: Icon,
  iconColor,
  bgColor,
  trend,
  alert = false,
}: {
  title: string;
  value: number;
  change: number | string;
  changeLabel: string;
  icon: any;
  iconColor: string;
  bgColor: string;
  trend?: 'up' | 'down';
  alert?: boolean;
}) {
  return (
    <Card className={alert ? 'border-red-200 dark:border-red-900 bg-red-50/50 dark:bg-red-950/50' : ''}>
      <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
        <CardTitle className="text-sm font-medium text-muted-foreground">{title}</CardTitle>
        <div className={`p-2 rounded-lg ${bgColor}`}>
          <Icon className={`h-4 w-4 ${iconColor}`} />
        </div>
      </CardHeader>
      <CardContent>
        <div className="text-2xl font-bold">{value.toLocaleString()}</div>
        <div className="flex items-center gap-1 mt-1">
          {trend === 'up' && <ArrowUpRight className="h-3 w-3 text-green-600" />}
          {trend === 'down' && <ArrowDownRight className="h-3 w-3 text-red-600" />}
          <p className={`text-xs ${alert ? 'text-red-600' : 'text-muted-foreground'}`}>
            <span className="font-medium">{typeof change === 'number' ? `+${change}` : change}</span> {changeLabel}
          </p>
        </div>
      </CardContent>
    </Card>
  );
}

// Quick Metric Card Component
function QuickMetricCard({
  title,
  value,
  label,
  icon: Icon,
  color,
}: {
  title: string;
  value: number;
  label: string;
  icon: any;
  color: 'blue' | 'green' | 'purple' | 'orange';
}) {
  const colors = {
    blue: 'bg-blue-50 dark:bg-blue-950 text-blue-600',
    green: 'bg-green-50 dark:bg-green-950 text-green-600',
    purple: 'bg-purple-50 dark:bg-purple-950 text-purple-600',
    orange: 'bg-orange-50 dark:bg-orange-950 text-orange-600',
  };

  return (
    <Card>
      <CardContent className="pt-4">
        <div className="flex items-center gap-3">
          <div className={`p-2 rounded-lg ${colors[color]}`}>
            <Icon className="h-4 w-4" />
          </div>
          <div>
            <p className="text-xs text-muted-foreground">{title}</p>
            <p className="text-xl font-bold">{value.toLocaleString()}</p>
            <p className="text-xs text-muted-foreground">{label}</p>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}

// Dashboard Skeleton
function DashboardSkeleton() {
  return (
    <div className="space-y-6 animate-pulse">
      <div className="flex items-center justify-between">
        <div>
          <Skeleton className="h-8 w-48" />
          <Skeleton className="h-4 w-64 mt-2" />
        </div>
        <Skeleton className="h-10 w-32" />
      </div>
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        {[1, 2, 3, 4].map((i) => (
          <Card key={i}>
            <CardHeader className="pb-2">
              <Skeleton className="h-4 w-24" />
            </CardHeader>
            <CardContent>
              <Skeleton className="h-8 w-20" />
              <Skeleton className="h-3 w-32 mt-2" />
            </CardContent>
          </Card>
        ))}
      </div>
      <div className="grid gap-4 md:grid-cols-3">
        {[1, 2, 3].map((i) => (
          <Card key={i}>
            <CardHeader className="pb-2">
              <Skeleton className="h-4 w-24" />
            </CardHeader>
            <CardContent>
              <Skeleton className="h-8 w-20" />
              <Skeleton className="h-3 w-32 mt-2" />
            </CardContent>
          </Card>
        ))}
      </div>
      <Skeleton className="h-10 w-96" />
      <div className="grid gap-4 md:grid-cols-2">
        <Card>
          <CardHeader>
            <Skeleton className="h-6 w-40" />
            <Skeleton className="h-4 w-56" />
          </CardHeader>
          <CardContent>
            <Skeleton className="h-[300px] w-full" />
          </CardContent>
        </Card>
        <Card>
          <CardHeader>
            <Skeleton className="h-6 w-40" />
            <Skeleton className="h-4 w-56" />
          </CardHeader>
          <CardContent>
            <Skeleton className="h-[300px] w-full" />
          </CardContent>
        </Card>
      </div>
      <Card>
        <CardHeader>
          <Skeleton className="h-6 w-48" />
          <Skeleton className="h-4 w-64" />
        </CardHeader>
        <CardContent>
          <div className="grid gap-3 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-5">
            {[1, 2, 3, 4, 5].map((i) => (
              <div key={i} className="p-4 border rounded-lg">
                <Skeleton className="h-5 w-5 mx-auto mb-2" />
                <Skeleton className="h-4 w-24 mx-auto mb-1" />
                <Skeleton className="h-3 w-16 mx-auto mb-2" />
                <Skeleton className="h-5 w-16 mx-auto" />
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
