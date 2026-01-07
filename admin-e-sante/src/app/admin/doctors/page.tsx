'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/components/providers/auth-provider';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Avatar, AvatarFallback } from '@/components/ui/avatar';
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from '@/components/ui/alert-dialog';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import { Textarea } from '@/components/ui/textarea';
import { Label } from '@/components/ui/label';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import { UserCheck, Eye, Check, X, Clock, FileText } from 'lucide-react';
import { usersService } from '@/lib/api';
import type { User, PaginatedResponse } from '@/lib/api';
import { toast } from '@/hooks/use-toast';
import { Skeleton } from '@/components/ui/skeleton';

export default function DoctorVerificationPage() {
  const router = useRouter();
  const { isAuthenticated, isLoading: authLoading } = useAuth();
  const [pendingDoctors, setPendingDoctors] = useState<User[]>([]);
  const [allDoctors, setAllDoctors] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedDoctor, setSelectedDoctor] = useState<User | null>(null);
  const [viewDialogOpen, setViewDialogOpen] = useState(false);
  const [verifyDialogOpen, setVerifyDialogOpen] = useState(false);
  const [rejectDialogOpen, setRejectDialogOpen] = useState(false);
  const [notes, setNotes] = useState('');
  const [actionLoading, setActionLoading] = useState(false);

  useEffect(() => {
    // Only fetch when authenticated
    if (!authLoading && isAuthenticated) {
      fetchPendingDoctors();
    }
  }, [authLoading, isAuthenticated]);

  const fetchPendingDoctors = async () => {
    try {
      setLoading(true);
      const response: PaginatedResponse<User> = await usersService.getUsers({
        page: 1,
        limit: 100,
        role: 'doctor',
      });
      const doctors = response.data || [];
      setAllDoctors(doctors);
      // Filter for pending verification (isVerified is false or undefined)
      const pending = doctors.filter(
        (doctor) => doctor.profile?.isVerified === false || doctor.profile?.isVerified === undefined
      );
      setPendingDoctors(pending);
    } catch (error: any) {
      toast({
        title: 'Error',
        description: error.message || 'Failed to fetch pending doctors',
        variant: 'destructive',
      });
    } finally {
      setLoading(false);
    }
  };

  // Calculate stats from real data
  const totalDoctors = allDoctors.length;
  const verifiedDoctors = allDoctors.filter(d => d.profile?.isVerified === true).length;
  const verificationRate = totalDoctors > 0 ? Math.round((verifiedDoctors / totalDoctors) * 100) : 0;

  const handleVerifyDoctor = async (isVerified: boolean) => {
    if (!selectedDoctor) return;

    try {
      setActionLoading(true);
      await usersService.verifyDoctor(selectedDoctor._id, isVerified);
      toast({
        title: 'Success',
        description: isVerified
          ? 'Doctor verified successfully'
          : 'Doctor verification rejected',
      });
      setVerifyDialogOpen(false);
      setRejectDialogOpen(false);
      setNotes('');
      setSelectedDoctor(null);
      fetchPendingDoctors();
    } catch (error: any) {
      toast({
        title: 'Error',
        description: error.message || 'Failed to update doctor verification',
        variant: 'destructive',
      });
    } finally {
      setActionLoading(false);
    }
  };

  const handleViewDoctor = (doctor: User) => {
    setSelectedDoctor(doctor);
    setViewDialogOpen(true);
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Doctor Verification</h1>
          <p className="text-muted-foreground">
            Review and verify doctor applications
          </p>
        </div>
        <Button variant="outline" onClick={() => router.push('/admin/users')}>
          Back to Users
        </Button>
      </div>

      {/* Stats Cards */}
      <div className="grid gap-4 md:grid-cols-3">
        <Card>
          <CardHeader className="pb-2">
            <CardDescription>Pending Verifications</CardDescription>
            <CardTitle className="text-2xl">{pendingDoctors.length}</CardTitle>
          </CardHeader>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardDescription>Total Doctors</CardDescription>
            <CardTitle className="text-2xl">{totalDoctors}</CardTitle>
          </CardHeader>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardDescription>Verification Rate</CardDescription>
            <CardTitle className="text-2xl">{verificationRate}%</CardTitle>
          </CardHeader>
        </Card>
      </div>

      {/* Pending Doctors Table */}
      <Card>
        <CardHeader>
          <CardTitle>Pending Verifications</CardTitle>
          <CardDescription>
            Doctors awaiting verification
          </CardDescription>
        </CardHeader>
        <CardContent>
          {loading ? (
            <div className="space-y-2">
              {[1, 2, 3, 4, 5].map((i) => (
                <Skeleton key={i} className="h-16 w-full" />
              ))}
            </div>
          ) : pendingDoctors.length === 0 ? (
            <div className="text-center py-12">
              <UserCheck className="h-12 w-12 text-muted-foreground mx-auto mb-4" />
              <h3 className="text-lg font-medium">No Pending Verifications</h3>
              <p className="text-muted-foreground mt-2">
                All doctors have been verified
              </p>
            </div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Doctor</TableHead>
                  <TableHead>Email</TableHead>
                  <TableHead>Specialty</TableHead>
                  <TableHead>Joined Date</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead className="text-right">Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {pendingDoctors.map((doctor) => (
                  <TableRow key={doctor._id}>
                    <TableCell>
                      <div className="flex items-center gap-3">
                        <Avatar className="h-10 w-10">
                          <AvatarFallback className="bg-green-600 text-white">
                            {doctor.profile?.firstName?.charAt(0) || 'D'}
                          </AvatarFallback>
                        </Avatar>
                        <div>
                          <p className="font-medium">
                            Dr. {doctor.profile?.firstName} {doctor.profile?.lastName}
                          </p>
                          <p className="text-xs text-muted-foreground">
                            {doctor.profile?.phone}
                          </p>
                        </div>
                      </div>
                    </TableCell>
                    <TableCell>{doctor.email}</TableCell>
                    <TableCell>
                      <Badge variant="secondary">General Medicine</Badge>
                    </TableCell>
                    <TableCell>
                      {new Date(doctor.createdAt).toLocaleDateString()}
                    </TableCell>
                    <TableCell>
                      <Badge variant="outline" className="gap-1">
                        <Clock className="h-3 w-3" />
                        Pending
                      </Badge>
                    </TableCell>
                    <TableCell className="text-right">
                      <Button
                        variant="ghost"
                        size="icon"
                        onClick={() => handleViewDoctor(doctor)}
                      >
                        <Eye className="h-4 w-4" />
                      </Button>
                      <Button
                        variant="ghost"
                        size="icon"
                        onClick={() => {
                          setSelectedDoctor(doctor);
                          setVerifyDialogOpen(true);
                        }}
                        className="text-green-600 hover:text-green-700"
                      >
                        <Check className="h-4 w-4" />
                      </Button>
                      <Button
                        variant="ghost"
                        size="icon"
                        onClick={() => {
                          setSelectedDoctor(doctor);
                          setRejectDialogOpen(true);
                        }}
                        className="text-red-600 hover:text-red-700"
                      >
                        <X className="h-4 w-4" />
                      </Button>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>

      {/* View Doctor Dialog */}
      <Dialog open={viewDialogOpen} onOpenChange={setViewDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Doctor Details</DialogTitle>
            <DialogDescription>Review doctor information</DialogDescription>
          </DialogHeader>
          {selectedDoctor && (
            <div className="space-y-4">
              <div className="flex items-center gap-4 pb-4 border-b">
                <Avatar className="h-16 w-16">
                  <AvatarFallback className="bg-green-600 text-white text-xl">
                    {selectedDoctor.profile?.firstName?.charAt(0)}
                  </AvatarFallback>
                </Avatar>
                <div>
                  <h3 className="text-lg font-semibold">
                    Dr. {selectedDoctor.profile?.firstName} {selectedDoctor.profile?.lastName}
                  </h3>
                  <p className="text-sm text-muted-foreground">
                    {selectedDoctor.email}
                  </p>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <Label>First Name</Label>
                  <p className="text-sm font-medium">{selectedDoctor.profile?.firstName}</p>
                </div>
                <div>
                  <Label>Last Name</Label>
                  <p className="text-sm font-medium">{selectedDoctor.profile?.lastName}</p>
                </div>
                <div>
                  <Label>Email</Label>
                  <p className="text-sm font-medium">{selectedDoctor.email}</p>
                </div>
                <div>
                  <Label>Phone</Label>
                  <p className="text-sm font-medium">{selectedDoctor.profile?.phone}</p>
                </div>
                <div>
                  <Label>Specialty</Label>
                  <p className="text-sm font-medium">General Medicine</p>
                </div>
                <div>
                  <Label>Joined Date</Label>
                  <p className="text-sm font-medium">
                    {new Date(selectedDoctor.createdAt).toLocaleDateString()}
                  </p>
                </div>
              </div>

              <div className="pt-4 border-t">
                <Button
                  className="w-full gap-2"
                  onClick={() => {
                    setViewDialogOpen(false);
                    setVerifyDialogOpen(true);
                  }}
                >
                  <Check className="h-4 w-4" />
                  Verify Doctor
                </Button>
              </div>
            </div>
          )}
        </DialogContent>
      </Dialog>

      {/* Verify Dialog */}
      <AlertDialog open={verifyDialogOpen} onOpenChange={setVerifyDialogOpen}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Verify Doctor?</AlertDialogTitle>
            <AlertDialogDescription>
              This will grant Dr. {selectedDoctor?.profile?.firstName} {selectedDoctor?.profile?.lastName} access to the platform as a verified doctor.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <div className="space-y-4 py-4">
            <div>
              <Label htmlFor="verify-notes">Notes (Optional)</Label>
              <Textarea
                id="verify-notes"
                placeholder="Add any verification notes..."
                value={notes}
                onChange={(e) => setNotes(e.target.value)}
              />
            </div>
          </div>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancel</AlertDialogCancel>
            <AlertDialogAction
              onClick={() => handleVerifyDoctor(true)}
              disabled={actionLoading}
              className="bg-green-600 hover:bg-green-700"
            >
              {actionLoading ? 'Processing...' : 'Verify'}
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>

      {/* Reject Dialog */}
      <AlertDialog open={rejectDialogOpen} onOpenChange={setRejectDialogOpen}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Reject Verification?</AlertDialogTitle>
            <AlertDialogDescription>
              This will reject the verification request for Dr. {selectedDoctor?.profile?.firstName} {selectedDoctor?.profile?.lastName}.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <div className="space-y-4 py-4">
            <div>
              <Label htmlFor="reject-notes">Rejection Reason *</Label>
              <Textarea
                id="reject-notes"
                placeholder="Please provide a reason for rejection..."
                value={notes}
                onChange={(e) => setNotes(e.target.value)}
              />
            </div>
          </div>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancel</AlertDialogCancel>
            <AlertDialogAction
              onClick={() => handleVerifyDoctor(false)}
              disabled={actionLoading || !notes.trim()}
              className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
            >
              {actionLoading ? 'Processing...' : 'Reject'}
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}
