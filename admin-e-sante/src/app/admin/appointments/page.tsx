'use client';

import { useEffect, useState } from 'react';
import { useAuth } from '@/components/providers/auth-provider';
import { useSearchParams } from 'next/navigation';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { Badge } from '@/components/ui/badge';
import { Avatar, AvatarFallback } from '@/components/ui/avatar';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Textarea } from '@/components/ui/textarea';
import { Label } from '@/components/ui/label';
import {
  Calendar,
  Clock,
  Search,
  Filter,
  CheckCircle,
  XCircle,
  RotateCcw,
  Trash2,
  BarChart3,
  X,
} from 'lucide-react';
import { appointmentsService } from '@/lib/api';
import type { Appointment, PaginatedResponse } from '@/lib/api';
import { toast } from '@/hooks/use-toast';
import { useDebounce } from '@reactuses/core';
import { Skeleton } from '@/components/ui/skeleton';
import { useSocket } from '@/components/providers/socket-provider';
import Link from 'next/link';

export default function AppointmentsPage() {
  const searchParams = useSearchParams();
  const initialDoctorId = searchParams.get('doctorId') || '';
  const initialPatientId = searchParams.get('patientId') || '';
  
  const { appointmentSocket } = useSocket();
  const { isAuthenticated, isLoading: authLoading } = useAuth();
  const [appointments, setAppointments] = useState<Appointment[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [status, setStatus] = useState('all');
  const [doctorId, setDoctorId] = useState(initialDoctorId);
  const [patientId, setPatientId] = useState(initialPatientId);
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [total, setTotal] = useState(0);

  const [selectedAppointment, setSelectedAppointment] = useState<Appointment | null>(null);
  const [actionDialogOpen, setActionDialogOpen] = useState(false);
  const [rescheduleDialogOpen, setRescheduleDialogOpen] = useState(false);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [actionType, setActionType] = useState<'confirm' | 'cancel' | null>(null);
  const [reason, setReason] = useState('');
  const [newDate, setNewDate] = useState('');
  const [newTime, setNewTime] = useState('');
  const [actionLoading, setActionLoading] = useState(false);

  const debouncedSearch = useDebounce(search, 500);

  useEffect(() => {
    // Only fetch when authenticated
    if (!authLoading && isAuthenticated) {
      fetchAppointments();
    }
  }, [debouncedSearch, status, page, doctorId, patientId, authLoading, isAuthenticated]);

  // Real-time socket updates
  useEffect(() => {
    if (!appointmentSocket) return;

    const handleAppointmentCreated = (data: any) => {
      toast({
        title: 'New Appointment',
        description: 'A new appointment has been booked',
      });
      // Only add if matches current filter
      if (status === 'all' || status === 'pending') {
        setAppointments((prev) => [data.appointment, ...prev]);
        setTotal((prev) => prev + 1);
      }
    };

    const handleAppointmentStatusChanged = (data: any) => {
      toast({
        title: 'Appointment Updated',
        description: `Appointment status changed to ${data.newStatus}`,
      });
      setAppointments((prev) =>
        prev.map((a) =>
          a._id === data.appointmentId ? { ...a, status: data.newStatus } : a
        )
      );
    };

    const handleAppointmentCancelled = (data: any) => {
      toast({
        title: 'Appointment Cancelled',
        description: 'An appointment has been cancelled',
        variant: 'destructive',
      });
      setAppointments((prev) =>
        prev.map((a) =>
          a._id === data.appointmentId ? { ...a, status: 'cancelled' } : a
        )
      );
    };

    const handleRescheduleRequested = (data: any) => {
      toast({
        title: 'Reschedule Request',
        description: 'A new reschedule request has been received',
      });
    };

    appointmentSocket.on('appointment_created', handleAppointmentCreated);
    appointmentSocket.on('appointment_status_changed', handleAppointmentStatusChanged);
    appointmentSocket.on('appointment_cancelled', handleAppointmentCancelled);
    appointmentSocket.on('reschedule_requested', handleRescheduleRequested);

    return () => {
      appointmentSocket.off('appointment_created');
      appointmentSocket.off('appointment_status_changed');
      appointmentSocket.off('appointment_cancelled');
      appointmentSocket.off('reschedule_requested');
    };
  }, [appointmentSocket, status]);

  const fetchAppointments = async () => {
    try {
      setLoading(true);
      const response: PaginatedResponse<Appointment> = await appointmentsService.getAllAppointments({
        page,
        limit: 20,
        status: status === 'all' ? undefined : status,
        doctorId: doctorId || undefined,
        patientId: patientId || undefined,
      });
      setAppointments(response.data || []);
      setTotalPages(response.pagination.pages);
      setTotal(response.pagination.total);
    } catch (error: any) {
      toast({
        title: 'Error',
        description: error.message || 'Failed to fetch appointments',
        variant: 'destructive',
      });
    } finally {
      setLoading(false);
    }
  };

  const clearFilters = () => {
    setDoctorId('');
    setPatientId('');
    setStatus('all');
    setSearch('');
    setPage(1);
  };

  const handleStatusChange = async () => {
    if (!selectedAppointment || !actionType) return;

    try {
      setActionLoading(true);
      await appointmentsService.updateAppointmentStatus(selectedAppointment._id, {
        status: actionType === 'confirm' ? 'confirmed' : 'cancelled',
        reason,
      });
      toast({
        title: 'Success',
        description: `Appointment ${actionType === 'confirm' ? 'confirmed' : 'cancelled'}`,
      });
      setActionDialogOpen(false);
      setReason('');
      setSelectedAppointment(null);
      setActionType(null);
      fetchAppointments();
    } catch (error: any) {
      toast({
        title: 'Error',
        description: error.message || 'Failed to update appointment',
        variant: 'destructive',
      });
    } finally {
      setActionLoading(false);
    }
  };

  const handleReschedule = async () => {
    if (!selectedAppointment) return;

    try {
      setActionLoading(true);
      await appointmentsService.rescheduleAppointment(selectedAppointment._id, {
        newDate,
        newTime,
        reason,
      });
      toast({
        title: 'Success',
        description: 'Appointment rescheduled successfully',
      });
      setRescheduleDialogOpen(false);
      setReason('');
      setNewDate('');
      setNewTime('');
      setSelectedAppointment(null);
      fetchAppointments();
    } catch (error: any) {
      toast({
        title: 'Error',
        description: error.message || 'Failed to reschedule appointment',
        variant: 'destructive',
      });
    } finally {
      setActionLoading(false);
    }
  };

  const handleDelete = async () => {
    if (!selectedAppointment) return;

    try {
      setActionLoading(true);
      await appointmentsService.deleteAppointment(selectedAppointment._id);
      toast({
        title: 'Success',
        description: 'Appointment deleted successfully',
      });
      setDeleteDialogOpen(false);
      setSelectedAppointment(null);
      fetchAppointments();
    } catch (error: any) {
      toast({
        title: 'Error',
        description: error.message || 'Failed to delete appointment',
        variant: 'destructive',
      });
    } finally {
      setActionLoading(false);
    }
  };

  const getStatusBadge = (status: string) => {
    const colors: Record<string, string> = {
      pending: 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200',
      confirmed: 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200',
      completed: 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200',
      cancelled: 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200',
    };
    return (
      <Badge className={colors[status] || 'bg-gray-100 text-gray-800'}>
        {status.charAt(0).toUpperCase() + status.slice(1)}
      </Badge>
    );
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Appointments</h1>
          <p className="text-muted-foreground">
            Manage all appointments on the platform
          </p>
        </div>
        <Link href="/admin/appointments/analytics">
          <Button>
            <BarChart3 className="h-4 w-4 mr-2" />
            View Analytics
          </Button>
        </Link>
      </div>

      {/* Active Filters */}
      {(doctorId || patientId) && (
        <Card className="bg-blue-50 dark:bg-blue-950 border-blue-200">
          <CardContent className="py-3 flex items-center justify-between">
            <div className="flex items-center gap-4">
              <Filter className="h-4 w-4 text-blue-600" />
              <span className="text-sm">
                Filtering by: 
                {doctorId && <Badge variant="secondary" className="ml-2">Doctor ID: {doctorId.slice(-6)}</Badge>}
                {patientId && <Badge variant="secondary" className="ml-2">Patient ID: {patientId.slice(-6)}</Badge>}
              </span>
            </div>
            <Button variant="ghost" size="sm" onClick={clearFilters}>
              <X className="h-4 w-4 mr-1" />
              Clear Filters
            </Button>
          </CardContent>
        </Card>
      )}

      {/* Stats Cards */}
      <div className="grid gap-4 md:grid-cols-4">
        <Card>
          <CardHeader className="pb-2">
            <CardDescription>Total Appointments</CardDescription>
            <CardTitle className="text-2xl">{total}</CardTitle>
          </CardHeader>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardDescription>Pending</CardDescription>
            <CardTitle className="text-2xl">
              {appointments.filter((a) => a.status === 'pending').length}
            </CardTitle>
          </CardHeader>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardDescription>Confirmed</CardDescription>
            <CardTitle className="text-2xl">
              {appointments.filter((a) => a.status === 'confirmed').length}
            </CardTitle>
          </CardHeader>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardDescription>Completed</CardDescription>
            <CardTitle className="text-2xl">
              {appointments.filter((a) => a.status === 'completed').length}
            </CardTitle>
          </CardHeader>
        </Card>
      </div>

      {/* Filters */}
      <Card>
        <CardContent className="pt-6">
          <div className="flex gap-4">
            <div className="flex-1 relative">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
              <Input
                placeholder="Search appointments..."
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                className="pl-10"
              />
            </div>
            <Select value={status} onValueChange={setStatus}>
              <SelectTrigger className="w-[180px]">
                <SelectValue placeholder="Status" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Status</SelectItem>
                <SelectItem value="pending">Pending</SelectItem>
                <SelectItem value="confirmed">Confirmed</SelectItem>
                <SelectItem value="completed">Completed</SelectItem>
                <SelectItem value="cancelled">Cancelled</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </CardContent>
      </Card>

      {/* Appointments Table */}
      <Card>
        <CardHeader>
          <CardTitle>All Appointments</CardTitle>
          <CardDescription>
            Showing {appointments.length} of {total} appointments
          </CardDescription>
        </CardHeader>
        <CardContent>
          {loading ? (
            <div className="space-y-2">
              {[1, 2, 3, 4, 5].map((i) => (
                <Skeleton key={i} className="h-16 w-full" />
              ))}
            </div>
          ) : (
            <>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Patient</TableHead>
                    <TableHead>Doctor</TableHead>
                    <TableHead>Date & Time</TableHead>
                    <TableHead>Status</TableHead>
                    <TableHead className="text-right">Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {appointments.map((appointment) => (
                    <TableRow key={appointment._id}>
                      <TableCell>
                        <div className="flex items-center gap-3">
                          <Avatar className="h-8 w-8">
                            <AvatarFallback className="bg-blue-600 text-white">
                              {appointment.patient.firstName?.charAt(0) || 'P'}
                            </AvatarFallback>
                          </Avatar>
                          <div>
                            <p className="font-medium">
                              {appointment.patient.firstName} {appointment.patient.lastName}
                            </p>
                          </div>
                        </div>
                      </TableCell>
                      <TableCell>
                        <div>
                          <p className="font-medium">
                            Dr. {appointment.doctor.firstName} {appointment.doctor.lastName}
                          </p>
                          <p className="text-xs text-muted-foreground">
                            {appointment.doctor.specialty}
                          </p>
                        </div>
                      </TableCell>
                      <TableCell>
                        <div className="flex items-center gap-2">
                          <Calendar className="h-4 w-4 text-muted-foreground" />
                          <span>{new Date(appointment.appointmentDate).toLocaleDateString()}</span>
                          <Clock className="h-4 w-4 text-muted-foreground ml-2" />
                          <span>{appointment.appointmentTime}</span>
                        </div>
                      </TableCell>
                      <TableCell>{getStatusBadge(appointment.status)}</TableCell>
                      <TableCell className="text-right">
                        {appointment.status === 'pending' && (
                          <>
                            <Button
                              variant="ghost"
                              size="icon"
                              onClick={() => {
                                setSelectedAppointment(appointment);
                                setActionType('confirm');
                                setActionDialogOpen(true);
                              }}
                              className="text-green-600 hover:text-green-700"
                            >
                              <CheckCircle className="h-4 w-4" />
                            </Button>
                            <Button
                              variant="ghost"
                              size="icon"
                              onClick={() => {
                                setSelectedAppointment(appointment);
                                setActionType('cancel');
                                setActionDialogOpen(true);
                              }}
                              className="text-red-600 hover:text-red-700"
                            >
                              <XCircle className="h-4 w-4" />
                            </Button>
                          </>
                        )}
                        {appointment.status !== 'cancelled' && (
                          <Button
                            variant="ghost"
                            size="icon"
                            onClick={() => {
                              setSelectedAppointment(appointment);
                              setRescheduleDialogOpen(true);
                            }}
                          >
                            <RotateCcw className="h-4 w-4" />
                          </Button>
                        )}
                        <Button
                          variant="ghost"
                          size="icon"
                          onClick={() => {
                            setSelectedAppointment(appointment);
                            setDeleteDialogOpen(true);
                          }}
                        >
                          <Trash2 className="h-4 w-4 text-destructive" />
                        </Button>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>

              {/* Pagination */}
              <div className="flex items-center justify-between mt-4">
                <p className="text-sm text-muted-foreground">
                  Page {page} of {totalPages}
                </p>
                <div className="flex gap-2">
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => setPage((p) => Math.max(1, p - 1))}
                    disabled={page === 1}
                  >
                    Previous
                  </Button>
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
                    disabled={page === totalPages}
                  >
                    Next
                  </Button>
                </div>
              </div>
            </>
          )}
        </CardContent>
      </Card>

      {/* Status Change Dialog */}
      <Dialog open={actionDialogOpen} onOpenChange={setActionDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>
              {actionType === 'confirm' ? 'Confirm Appointment?' : 'Cancel Appointment?'}
            </DialogTitle>
            <DialogDescription>
              {actionType === 'confirm'
                ? 'This will confirm the appointment and notify both patient and doctor.'
                : 'This will cancel the appointment and notify both patient and doctor.'}
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4">
            <div>
              <Label htmlFor="reason">Reason (Optional)</Label>
              <Textarea
                id="reason"
                placeholder="Provide a reason for this action..."
                value={reason}
                onChange={(e) => setReason(e.target.value)}
              />
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setActionDialogOpen(false)}>
              Cancel
            </Button>
            <Button
              variant={actionType === 'cancel' ? 'destructive' : 'default'}
              onClick={handleStatusChange}
              disabled={actionLoading}
            >
              {actionLoading ? 'Processing...' : actionType === 'confirm' ? 'Confirm' : 'Cancel'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Reschedule Dialog */}
      <Dialog open={rescheduleDialogOpen} onOpenChange={setRescheduleDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Reschedule Appointment</DialogTitle>
            <DialogDescription>
              Choose a new date and time for this appointment
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <Label htmlFor="newDate">New Date</Label>
                <Input
                  id="newDate"
                  type="date"
                  value={newDate}
                  onChange={(e) => setNewDate(e.target.value)}
                />
              </div>
              <div>
                <Label htmlFor="newTime">New Time</Label>
                <Input
                  id="newTime"
                  type="time"
                  value={newTime}
                  onChange={(e) => setNewTime(e.target.value)}
                />
              </div>
            </div>
            <div>
              <Label htmlFor="rescheduleReason">Reason (Optional)</Label>
              <Textarea
                id="rescheduleReason"
                placeholder="Provide a reason for rescheduling..."
                value={reason}
                onChange={(e) => setReason(e.target.value)}
              />
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setRescheduleDialogOpen(false)}>
              Cancel
            </Button>
            <Button onClick={handleReschedule} disabled={actionLoading || !newDate || !newTime}>
              {actionLoading ? 'Processing...' : 'Reschedule'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Delete Confirmation Dialog */}
      <Dialog open={deleteDialogOpen} onOpenChange={setDeleteDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Delete Appointment?</DialogTitle>
            <DialogDescription>
              This action cannot be undone. Are you sure you want to delete this appointment?
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setDeleteDialogOpen(false)}>
              Cancel
            </Button>
            <Button
              variant="destructive"
              onClick={handleDelete}
              disabled={actionLoading}
            >
              {actionLoading ? 'Deleting...' : 'Delete'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
