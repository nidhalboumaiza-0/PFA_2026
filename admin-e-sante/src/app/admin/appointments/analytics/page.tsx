'use client';

import { useEffect, useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Progress } from '@/components/ui/progress';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Avatar, AvatarFallback } from '@/components/ui/avatar';
import {
  Calendar,
  Users,
  UserCheck,
  MapPin,
  TrendingUp,
  TrendingDown,
  Activity,
  Clock,
  CheckCircle,
  XCircle,
  AlertCircle,
  Loader2,
  BarChart3,
  PieChart,
  ArrowUpRight,
  ArrowDownRight,
  Eye,
  Stethoscope,
  UserRound
} from 'lucide-react';
import { appointmentsService, AdvancedAnalyticsResponse, DoctorAppointmentStats, PatientAppointmentStats, RegionStats } from '@/lib/api';
import { format } from 'date-fns';
import Link from 'next/link';

export default function AppointmentsAnalyticsPage() {
  const [analytics, setAnalytics] = useState<AdvancedAnalyticsResponse | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState('overview');

  useEffect(() => {
    fetchAnalytics();
  }, []);

  const fetchAnalytics = async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await appointmentsService.getAdvancedAnalytics();
      setAnalytics(data);
    } catch (err: any) {
      console.error('Failed to fetch analytics:', err);
      setError(err.message || 'Failed to load analytics');
    } finally {
      setLoading(false);
    }
  };

  const getCompletionColor = (rate: number) => {
    if (rate >= 80) return 'text-green-600';
    if (rate >= 60) return 'text-yellow-600';
    return 'text-red-600';
  };

  const getGrowthIcon = (growth: number) => {
    if (growth > 0) return <ArrowUpRight className="h-4 w-4 text-green-500" />;
    if (growth < 0) return <ArrowDownRight className="h-4 w-4 text-red-500" />;
    return null;
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-96">
        <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex flex-col items-center justify-center h-96">
        <AlertCircle className="h-12 w-12 text-red-500 mb-4" />
        <p className="text-lg font-medium">{error}</p>
        <Button onClick={fetchAnalytics} className="mt-4">Retry</Button>
      </div>
    );
  }

  if (!analytics) return null;

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Appointments Analytics</h1>
          <p className="text-muted-foreground">
            Advanced insights and statistics for your platform
          </p>
        </div>
        <Link href="/admin/appointments">
          <Button variant="outline">
            <Calendar className="h-4 w-4 mr-2" />
            View All Appointments
          </Button>
        </Link>
      </div>

      <Tabs value={activeTab} onValueChange={setActiveTab}>
        <TabsList className="grid w-full grid-cols-5">
          <TabsTrigger value="overview" className="flex items-center gap-2">
            <BarChart3 className="h-4 w-4" />
            Overview
          </TabsTrigger>
          <TabsTrigger value="doctors" className="flex items-center gap-2">
            <Stethoscope className="h-4 w-4" />
            By Doctor
          </TabsTrigger>
          <TabsTrigger value="patients" className="flex items-center gap-2">
            <UserRound className="h-4 w-4" />
            By Patient
          </TabsTrigger>
          <TabsTrigger value="regions" className="flex items-center gap-2">
            <MapPin className="h-4 w-4" />
            By Region
          </TabsTrigger>
          <TabsTrigger value="trends" className="flex items-center gap-2">
            <Activity className="h-4 w-4" />
            Trends
          </TabsTrigger>
        </TabsList>

        {/* Overview Tab */}
        <TabsContent value="overview" className="space-y-6">
          {/* Key Metrics */}
          <div className="grid gap-4 md:grid-cols-4">
            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">Total Appointments</CardTitle>
                <Calendar className="h-4 w-4 text-muted-foreground" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold">{analytics.overview.total}</div>
                <div className="flex items-center gap-1 text-xs text-muted-foreground">
                  {getGrowthIcon(analytics.reliability.weeklyGrowth)}
                  <span className={analytics.reliability.weeklyGrowth >= 0 ? 'text-green-600' : 'text-red-600'}>
                    {analytics.reliability.weeklyGrowth >= 0 ? '+' : ''}{analytics.reliability.weeklyGrowth}%
                  </span>
                  <span>vs last week</span>
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">Completion Rate</CardTitle>
                <CheckCircle className="h-4 w-4 text-green-500" />
              </CardHeader>
              <CardContent>
                <div className={`text-2xl font-bold ${getCompletionColor(analytics.reliability.completionRate)}`}>
                  {analytics.reliability.completionRate}%
                </div>
                <p className="text-xs text-muted-foreground">
                  {analytics.overview.completed} completed appointments
                </p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">Cancellation Rate</CardTitle>
                <XCircle className="h-4 w-4 text-red-500" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold text-red-600">
                  {analytics.reliability.cancellationRate}%
                </div>
                <p className="text-xs text-muted-foreground">
                  {analytics.overview.cancelled} cancelled
                </p>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                <CardTitle className="text-sm font-medium">No-Show Rate</CardTitle>
                <AlertCircle className="h-4 w-4 text-yellow-500" />
              </CardHeader>
              <CardContent>
                <div className="text-2xl font-bold text-yellow-600">
                  {analytics.reliability.noShowRate}%
                </div>
                <p className="text-xs text-muted-foreground">
                  {analytics.overview.noShow} no-shows
                </p>
              </CardContent>
            </Card>
          </div>

          {/* Status Distribution */}
          <div className="grid gap-4 md:grid-cols-2">
            <Card>
              <CardHeader>
                <CardTitle>Status Distribution</CardTitle>
                <CardDescription>Breakdown of all appointments by status</CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                {[
                  { label: 'Completed', value: analytics.overview.completed, color: 'bg-green-500' },
                  { label: 'Confirmed', value: analytics.overview.confirmed, color: 'bg-blue-500' },
                  { label: 'Pending', value: analytics.overview.pending, color: 'bg-yellow-500' },
                  { label: 'Cancelled', value: analytics.overview.cancelled, color: 'bg-red-500' },
                  { label: 'Rejected', value: analytics.overview.rejected, color: 'bg-gray-500' },
                  { label: 'No-Show', value: analytics.overview.noShow, color: 'bg-orange-500' },
                ].map((item) => {
                  const percentage = analytics.overview.total > 0 
                    ? (item.value / analytics.overview.total) * 100 
                    : 0;
                  return (
                    <div key={item.label} className="space-y-1">
                      <div className="flex justify-between text-sm">
                        <span>{item.label}</span>
                        <span className="text-muted-foreground">{item.value} ({percentage.toFixed(1)}%)</span>
                      </div>
                      <Progress value={percentage} className={`h-2 [&>div]:${item.color}`} />
                    </div>
                  );
                })}
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>Platform Metrics</CardTitle>
                <CardDescription>Key reliability indicators</CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-2 p-4 border rounded-lg">
                    <div className="flex items-center gap-2">
                      <TrendingUp className="h-4 w-4 text-blue-500" />
                      <span className="text-sm font-medium">Referrals</span>
                    </div>
                    <p className="text-2xl font-bold">{analytics.overview.referrals}</p>
                    <p className="text-xs text-muted-foreground">
                      {analytics.reliability.referralRate}% of total
                    </p>
                  </div>

                  <div className="space-y-2 p-4 border rounded-lg">
                    <div className="flex items-center gap-2">
                      <Activity className="h-4 w-4 text-purple-500" />
                      <span className="text-sm font-medium">Rescheduled</span>
                    </div>
                    <p className="text-2xl font-bold">{analytics.overview.rescheduled}</p>
                    <p className="text-xs text-muted-foreground">
                      {analytics.reliability.rescheduleRate}% of total
                    </p>
                  </div>

                  <div className="space-y-2 p-4 border rounded-lg">
                    <div className="flex items-center gap-2">
                      <Calendar className="h-4 w-4 text-green-500" />
                      <span className="text-sm font-medium">This Week</span>
                    </div>
                    <p className="text-2xl font-bold">{analytics.reliability.thisWeekTotal}</p>
                    <p className="text-xs text-muted-foreground">appointments</p>
                  </div>

                  <div className="space-y-2 p-4 border rounded-lg">
                    <div className="flex items-center gap-2">
                      <Calendar className="h-4 w-4 text-gray-500" />
                      <span className="text-sm font-medium">Last Week</span>
                    </div>
                    <p className="text-2xl font-bold">{analytics.reliability.lastWeekTotal}</p>
                    <p className="text-xs text-muted-foreground">appointments</p>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>

          {/* Top Performers */}
          <div className="grid gap-4 md:grid-cols-2">
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <TrendingUp className="h-5 w-5 text-green-500" />
                  Top Doctors by Volume
                </CardTitle>
                <CardDescription>Doctors with most appointments</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-3">
                  {analytics.doctorStats.slice(0, 5).map((doctor, idx) => (
                    <div key={doctor.doctorId} className="flex items-center justify-between p-2 rounded-lg hover:bg-muted/50">
                      <div className="flex items-center gap-3">
                        <span className="text-sm font-medium text-muted-foreground w-6">#{idx + 1}</span>
                        <Avatar className="h-8 w-8">
                          <AvatarFallback className="bg-blue-600 text-white text-xs">
                            {doctor.doctor?.firstName?.charAt(0) || 'D'}
                          </AvatarFallback>
                        </Avatar>
                        <div>
                          <p className="text-sm font-medium">
                            Dr. {doctor.doctor?.firstName} {doctor.doctor?.lastName}
                          </p>
                          <p className="text-xs text-muted-foreground">{doctor.doctor?.specialty}</p>
                        </div>
                      </div>
                      <div className="text-right">
                        <p className="text-sm font-bold">{doctor.total}</p>
                        <p className="text-xs text-green-600">{doctor.completionRate}% completed</p>
                      </div>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Users className="h-5 w-5 text-blue-500" />
                  Most Active Patients
                </CardTitle>
                <CardDescription>Patients with most bookings</CardDescription>
              </CardHeader>
              <CardContent>
                <div className="space-y-3">
                  {analytics.patientStats.slice(0, 5).map((patient, idx) => (
                    <div key={patient.patientId} className="flex items-center justify-between p-2 rounded-lg hover:bg-muted/50">
                      <div className="flex items-center gap-3">
                        <span className="text-sm font-medium text-muted-foreground w-6">#{idx + 1}</span>
                        <Avatar className="h-8 w-8">
                          <AvatarFallback className="bg-green-600 text-white text-xs">
                            {patient.patient?.firstName?.charAt(0) || 'P'}
                          </AvatarFallback>
                        </Avatar>
                        <div>
                          <p className="text-sm font-medium">
                            {patient.patient?.firstName} {patient.patient?.lastName}
                          </p>
                          <p className="text-xs text-muted-foreground">
                            {patient.uniqueDoctors} doctors visited
                          </p>
                        </div>
                      </div>
                      <div className="text-right">
                        <p className="text-sm font-bold">{patient.total}</p>
                        <p className="text-xs text-muted-foreground">{patient.completed} completed</p>
                      </div>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        {/* By Doctor Tab */}
        <TabsContent value="doctors" className="space-y-6">
          <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
            {analytics.doctorStats.map((doctor) => (
              <Card key={doctor.doctorId} className="hover:shadow-md transition-shadow">
                <CardHeader className="pb-2">
                  <div className="flex items-center gap-3">
                    <Avatar className="h-12 w-12">
                      <AvatarFallback className="bg-blue-600 text-white">
                        {doctor.doctor?.firstName?.charAt(0) || 'D'}
                      </AvatarFallback>
                    </Avatar>
                    <div className="flex-1">
                      <CardTitle className="text-base">
                        Dr. {doctor.doctor?.firstName} {doctor.doctor?.lastName}
                      </CardTitle>
                      <CardDescription>{doctor.doctor?.specialty || 'General'}</CardDescription>
                    </div>
                  </div>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div className="grid grid-cols-3 gap-2 text-center">
                    <div className="p-2 bg-muted rounded-lg">
                      <p className="text-lg font-bold">{doctor.total}</p>
                      <p className="text-xs text-muted-foreground">Total</p>
                    </div>
                    <div className="p-2 bg-green-50 dark:bg-green-950 rounded-lg">
                      <p className="text-lg font-bold text-green-600">{doctor.completed}</p>
                      <p className="text-xs text-muted-foreground">Completed</p>
                    </div>
                    <div className="p-2 bg-yellow-50 dark:bg-yellow-950 rounded-lg">
                      <p className="text-lg font-bold text-yellow-600">{doctor.pending + doctor.confirmed}</p>
                      <p className="text-xs text-muted-foreground">Active</p>
                    </div>
                  </div>

                  <div className="space-y-2">
                    <div className="flex justify-between text-sm">
                      <span>Completion Rate</span>
                      <span className={getCompletionColor(doctor.completionRate)}>
                        {doctor.completionRate}%
                      </span>
                    </div>
                    <Progress value={doctor.completionRate} className="h-2" />
                  </div>

                  <div className="flex justify-between text-xs text-muted-foreground border-t pt-2">
                    <span className="flex items-center gap-1">
                      <XCircle className="h-3 w-3 text-red-500" />
                      {doctor.cancelled} cancelled
                    </span>
                    <span className="flex items-center gap-1">
                      <AlertCircle className="h-3 w-3 text-yellow-500" />
                      {doctor.noShow} no-show
                    </span>
                  </div>

                  {doctor.doctor?.city && (
                    <div className="flex items-center gap-1 text-xs text-muted-foreground">
                      <MapPin className="h-3 w-3" />
                      {doctor.doctor.city}, {doctor.doctor.state}
                    </div>
                  )}

                  <Link href={`/admin/appointments?doctorId=${doctor.doctorId}`}>
                    <Button variant="outline" size="sm" className="w-full">
                      <Eye className="h-4 w-4 mr-2" />
                      View Appointments
                    </Button>
                  </Link>
                </CardContent>
              </Card>
            ))}
          </div>
        </TabsContent>

        {/* By Patient Tab */}
        <TabsContent value="patients" className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>Patient Appointment Statistics</CardTitle>
              <CardDescription>Top 50 patients by appointment volume</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-2">
                {analytics.patientStats.map((patient, idx) => (
                  <div 
                    key={patient.patientId} 
                    className="flex items-center justify-between p-3 border rounded-lg hover:bg-muted/50 transition-colors"
                  >
                    <div className="flex items-center gap-4">
                      <span className="text-sm font-medium text-muted-foreground w-8">#{idx + 1}</span>
                      <Avatar className="h-10 w-10">
                        <AvatarFallback className="bg-green-600 text-white">
                          {patient.patient?.firstName?.charAt(0) || 'P'}
                        </AvatarFallback>
                      </Avatar>
                      <div>
                        <p className="font-medium">
                          {patient.patient?.firstName} {patient.patient?.lastName}
                        </p>
                        {patient.patient?.city && (
                          <p className="text-xs text-muted-foreground flex items-center gap-1">
                            <MapPin className="h-3 w-3" />
                            {patient.patient.city}, {patient.patient.state}
                          </p>
                        )}
                      </div>
                    </div>

                    <div className="flex items-center gap-6">
                      <div className="text-center">
                        <p className="text-lg font-bold">{patient.total}</p>
                        <p className="text-xs text-muted-foreground">Total</p>
                      </div>
                      <div className="text-center">
                        <p className="text-lg font-bold text-green-600">{patient.completed}</p>
                        <p className="text-xs text-muted-foreground">Completed</p>
                      </div>
                      <div className="text-center">
                        <p className="text-lg font-bold text-blue-600">{patient.uniqueDoctors}</p>
                        <p className="text-xs text-muted-foreground">Doctors</p>
                      </div>
                      <div className="text-center">
                        <p className="text-lg font-bold text-red-600">{patient.cancelled}</p>
                        <p className="text-xs text-muted-foreground">Cancelled</p>
                      </div>
                      <Link href={`/admin/appointments?patientId=${patient.patientId}`}>
                        <Button variant="ghost" size="sm">
                          <Eye className="h-4 w-4" />
                        </Button>
                      </Link>
                    </div>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* By Region Tab */}
        <TabsContent value="regions" className="space-y-6">
          <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
            {analytics.regionStats.map((region) => (
              <Card key={region.region} className="hover:shadow-md transition-shadow">
                <CardHeader className="pb-2">
                  <div className="flex items-center gap-2">
                    <div className="p-2 bg-blue-100 dark:bg-blue-900 rounded-lg">
                      <MapPin className="h-5 w-5 text-blue-600 dark:text-blue-400" />
                    </div>
                    <div>
                      <CardTitle className="text-base">{region.city}</CardTitle>
                      <CardDescription>{region.state}</CardDescription>
                    </div>
                  </div>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div className="grid grid-cols-2 gap-4">
                    <div className="text-center p-3 bg-muted rounded-lg">
                      <p className="text-2xl font-bold">{region.total}</p>
                      <p className="text-xs text-muted-foreground">Appointments</p>
                    </div>
                    <div className="text-center p-3 bg-muted rounded-lg">
                      <p className="text-2xl font-bold">{region.doctors}</p>
                      <p className="text-xs text-muted-foreground">Doctors</p>
                    </div>
                  </div>

                  <div className="space-y-2">
                    <div className="flex justify-between text-sm">
                      <span>Completion Rate</span>
                      <span className={getCompletionColor(parseFloat(region.completionRate))}>
                        {region.completionRate}%
                      </span>
                    </div>
                    <Progress value={parseFloat(region.completionRate)} className="h-2" />
                  </div>

                  <div className="flex justify-between text-sm text-muted-foreground">
                    <span className="flex items-center gap-1">
                      <CheckCircle className="h-4 w-4 text-green-500" />
                      {region.completed} completed
                    </span>
                    <span className="flex items-center gap-1">
                      <XCircle className="h-4 w-4 text-red-500" />
                      {region.cancelled} cancelled
                    </span>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>

          {analytics.regionStats.length === 0 && (
            <Card>
              <CardContent className="flex flex-col items-center justify-center py-12">
                <MapPin className="h-12 w-12 text-muted-foreground mb-4" />
                <p className="text-lg font-medium">No region data available</p>
                <p className="text-sm text-muted-foreground">
                  Region data will appear when doctors have location information
                </p>
              </CardContent>
            </Card>
          )}
        </TabsContent>

        {/* Trends Tab */}
        <TabsContent value="trends" className="space-y-6">
          {/* Busiest Days */}
          <Card>
            <CardHeader>
              <CardTitle>Busiest Days of the Week</CardTitle>
              <CardDescription>Appointment distribution by day</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-3">
                {analytics.trends.busiestDays.map((day) => {
                  const maxCount = Math.max(...analytics.trends.busiestDays.map(d => d.count));
                  const percentage = maxCount > 0 ? (day.count / maxCount) * 100 : 0;
                  return (
                    <div key={day.day} className="flex items-center gap-4">
                      <span className="w-24 text-sm font-medium">{day.day}</span>
                      <div className="flex-1">
                        <Progress value={percentage} className="h-6" />
                      </div>
                      <span className="w-16 text-right text-sm font-bold">{day.count}</span>
                    </div>
                  );
                })}
              </div>
            </CardContent>
          </Card>

          {/* Peak Hours */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Clock className="h-5 w-5" />
                Peak Appointment Hours
              </CardTitle>
              <CardDescription>Most popular time slots</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-2 md:grid-cols-5 gap-4">
                {analytics.trends.peakHours.map((hour, idx) => (
                  <div 
                    key={hour.time} 
                    className={`p-4 rounded-lg text-center ${
                      idx === 0 ? 'bg-blue-100 dark:bg-blue-900 border-2 border-blue-500' : 'bg-muted'
                    }`}
                  >
                    <p className="text-lg font-bold">{hour.time}</p>
                    <p className="text-sm text-muted-foreground">{hour.count} appointments</p>
                    {idx === 0 && (
                      <Badge className="mt-2" variant="default">Most Popular</Badge>
                    )}
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>

          {/* Daily Trend */}
          <Card>
            <CardHeader>
              <CardTitle>Daily Appointment Trend (Last 30 Days)</CardTitle>
              <CardDescription>New appointments created per day</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-2 max-h-96 overflow-y-auto">
                {analytics.trends.daily.map((day) => {
                  const maxTotal = Math.max(...analytics.trends.daily.map(d => d.total));
                  const percentage = maxTotal > 0 ? (day.total / maxTotal) * 100 : 0;
                  return (
                    <div key={day._id} className="flex items-center gap-4 py-1">
                      <span className="w-24 text-xs text-muted-foreground">
                        {format(new Date(day._id), 'MMM d')}
                      </span>
                      <div className="flex-1 flex items-center gap-2">
                        <Progress value={percentage} className="h-4 flex-1" />
                        <div className="flex gap-2 text-xs min-w-[100px]">
                          <span className="text-green-600">{day.completed}✓</span>
                          <span className="text-red-600">{day.cancelled}✗</span>
                        </div>
                      </div>
                      <span className="w-10 text-right text-sm font-medium">{day.total}</span>
                    </div>
                  );
                })}
              </div>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}
