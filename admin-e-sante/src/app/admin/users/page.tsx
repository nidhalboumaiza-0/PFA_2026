'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/components/providers/auth-provider';
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
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from '@/components/ui/alert-dialog';
import { Search, Filter, MoreVertical, Eye, Ban, Trash2, UserPlus, Mail, Phone, Calendar, MapPin, GraduationCap, Briefcase, Star, Shield, Heart, AlertCircle, Building } from 'lucide-react';
import { usersService } from '@/lib/api';
import type { User, PaginatedResponse } from '@/lib/api';
import { toast } from '@/hooks/use-toast';
import { useDebounce } from '@reactuses/core';
import { Separator } from '@/components/ui/separator';
import { Skeleton } from '@/components/ui/skeleton';
import { useSocket } from '@/components/providers/socket-provider';

export default function UsersPage() {
  const router = useRouter();
  const { userSocket } = useSocket();
  const { isAuthenticated, isLoading: authLoading } = useAuth();
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [role, setRole] = useState('all');
  const [status, setStatus] = useState('all');
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [total, setTotal] = useState(0);

  const [selectedUser, setSelectedUser] = useState<User | null>(null);
  const [viewDialogOpen, setViewDialogOpen] = useState(false);
  const [statusDialogOpen, setStatusDialogOpen] = useState(false);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [statusReason, setStatusReason] = useState('');
  const [actionLoading, setActionLoading] = useState(false);

  const debouncedSearch = useDebounce(search, 500);

  useEffect(() => {
    // Only fetch when authenticated
    if (!authLoading && isAuthenticated) {
      fetchUsers();
    }
  }, [debouncedSearch, role, status, page, authLoading, isAuthenticated]);

  // Real-time socket updates
  useEffect(() => {
    if (!userSocket) return;

    const handleNewUser = (newUser: any) => {
      toast({
        title: 'New User Registered',
        description: `New ${newUser.role}: ${newUser.name || newUser.email}`,
      });
      // Only add if matches current filter
      if (role === 'all' || role === newUser.role) {
        setUsers((prev) => [newUser, ...prev]);
        setTotal((prev) => prev + 1);
      }
    };

    const handleUserStatusChanged = (data: any) => {
      toast({
        title: 'User Status Changed',
        description: `User status has been updated`,
      });
      setUsers((prev) =>
        prev.map((u) => (u._id === data.userId ? { ...u, isActive: data.isActive } : u))
      );
    };

    const handleUserDeleted = (data: any) => {
      toast({
        title: 'User Deleted',
        description: `A user has been deleted`,
        variant: 'destructive',
      });
      setUsers((prev) => prev.filter((u) => u._id !== data.userId));
      setTotal((prev) => Math.max(0, prev - 1));
    };

    userSocket.on('new_user_registered', handleNewUser);
    userSocket.on('user_status_changed', handleUserStatusChanged);
    userSocket.on('user_deleted', handleUserDeleted);

    return () => {
      userSocket.off('new_user_registered');
      userSocket.off('user_status_changed');
      userSocket.off('user_deleted');
    };
  }, [userSocket, role]);

  const fetchUsers = async () => {
    try {
      setLoading(true);
      const response: PaginatedResponse<User> = await usersService.getUsers({
        page,
        limit: 20,
        role: role === 'all' ? undefined : role,
        status: status === 'all' ? undefined : status,
        search: debouncedSearch || undefined,
      });
      setUsers(response.data || []);
      setTotalPages(response.pagination.pages);
      setTotal(response.pagination.total);
    } catch (error: any) {
      toast({
        title: 'Error',
        description: error.message || 'Failed to fetch users',
        variant: 'destructive',
      });
    } finally {
      setLoading(false);
    }
  };

  const handleViewUser = (user: User) => {
    setSelectedUser(user);
    setViewDialogOpen(true);
  };

  const handleStatusChange = async () => {
    if (!selectedUser) return;

    try {
      setActionLoading(true);
      await usersService.updateUserStatus(selectedUser._id, {
        isActive: !selectedUser.isActive,
        reason: statusReason,
      });
      toast({
        title: 'Success',
        description: `User ${selectedUser.isActive ? 'deactivated' : 'activated'} successfully`,
      });
      setStatusDialogOpen(false);
      setStatusReason('');
      setSelectedUser(null);
      fetchUsers();
    } catch (error: any) {
      toast({
        title: 'Error',
        description: error.message || 'Failed to update user status',
        variant: 'destructive',
      });
    } finally {
      setActionLoading(false);
    }
  };

  const handleDeleteUser = async () => {
    if (!selectedUser) return;

    try {
      setActionLoading(true);
      await usersService.deleteUser(selectedUser._id);
      toast({
        title: 'Success',
        description: 'User deleted successfully',
      });
      setDeleteDialogOpen(false);
      setSelectedUser(null);
      fetchUsers();
    } catch (error: any) {
      toast({
        title: 'Error',
        description: error.message || 'Failed to delete user',
        variant: 'destructive',
      });
    } finally {
      setActionLoading(false);
    }
  };

  const getRoleBadge = (userRole: string) => {
    const colors: Record<string, string> = {
      admin: 'bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-200',
      doctor: 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200',
      patient: 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200',
    };
    return (
      <Badge className={colors[userRole] || 'bg-gray-100 text-gray-800'}>
        {userRole}
      </Badge>
    );
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Users</h1>
          <p className="text-muted-foreground">
            Manage all users on the platform
          </p>
        </div>
        <Button onClick={() => router.push('/admin/doctors')}>
          <UserPlus className="mr-2 h-4 w-4" />
          Doctor Verifications
        </Button>
      </div>

      {/* Stats Cards */}
      <div className="grid gap-4 md:grid-cols-4">
        <Card>
          <CardHeader className="pb-2">
            <CardDescription>Total Users</CardDescription>
            <CardTitle className="text-2xl">{total}</CardTitle>
          </CardHeader>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardDescription>Doctors</CardDescription>
            <CardTitle className="text-2xl">
              {users.filter((u) => u.role === 'doctor').length}
            </CardTitle>
          </CardHeader>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardDescription>Patients</CardDescription>
            <CardTitle className="text-2xl">
              {users.filter((u) => u.role === 'patient').length}
            </CardTitle>
          </CardHeader>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardDescription>Active Users</CardDescription>
            <CardTitle className="text-2xl">
              {users.filter((u) => u.isActive).length}
            </CardTitle>
          </CardHeader>
        </Card>
      </div>

      {/* Filters */}
      <Card>
        <CardHeader>
          <CardTitle>Filter Users</CardTitle>
          <CardDescription>Search and filter users</CardDescription>
        </CardHeader>
        <CardContent>
          <div className="flex gap-4">
            <div className="flex-1 relative">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
              <Input
                placeholder="Search by name or email..."
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                className="pl-10"
              />
            </div>
            <Select value={role} onValueChange={setRole}>
              <SelectTrigger className="w-[150px]">
                <SelectValue placeholder="Role" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Roles</SelectItem>
                <SelectItem value="patient">Patients</SelectItem>
                <SelectItem value="doctor">Doctors</SelectItem>
                <SelectItem value="admin">Admins</SelectItem>
              </SelectContent>
            </Select>
            <Select value={status} onValueChange={setStatus}>
              <SelectTrigger className="w-[150px]">
                <SelectValue placeholder="Status" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Status</SelectItem>
                <SelectItem value="active">Active</SelectItem>
                <SelectItem value="inactive">Inactive</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </CardContent>
      </Card>

      {/* Users Table */}
      <Card>
        <CardHeader>
          <CardTitle>All Users</CardTitle>
          <CardDescription>
            Showing {users.length} of {total} users
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
                    <TableHead>User</TableHead>
                    <TableHead>Email</TableHead>
                    <TableHead>Role</TableHead>
                    <TableHead>Status</TableHead>
                    <TableHead>Joined</TableHead>
                    <TableHead className="text-right">Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {users.map((user) => (
                    <TableRow key={user._id}>
                      <TableCell>
                        <div className="flex items-center gap-3">
                          <Avatar className="h-8 w-8">
                            <AvatarFallback className="bg-blue-600 text-white">
                              {user.profile?.firstName?.charAt(0) || 'U'}
                            </AvatarFallback>
                          </Avatar>
                          <div>
                            <p className="font-medium">
                              {user.profile?.firstName} {user.profile?.lastName}
                            </p>
                            <p className="text-xs text-muted-foreground">
                              {user.profile?.phone}
                            </p>
                          </div>
                        </div>
                      </TableCell>
                      <TableCell>{user.email}</TableCell>
                      <TableCell>{getRoleBadge(user.role)}</TableCell>
                      <TableCell>
                        <Badge variant={user.isActive ? 'default' : 'secondary'}>
                          {user.isActive ? 'Active' : 'Inactive'}
                        </Badge>
                      </TableCell>
                      <TableCell>
                        {new Date(user.createdAt).toLocaleDateString()}
                      </TableCell>
                      <TableCell className="text-right">
                        <Button
                          variant="ghost"
                          size="icon"
                          onClick={() => handleViewUser(user)}
                        >
                          <Eye className="h-4 w-4" />
                        </Button>
                        <Button
                          variant="ghost"
                          size="icon"
                          onClick={() => {
                            setSelectedUser(user);
                            setStatusDialogOpen(true);
                          }}
                        >
                          <Ban className="h-4 w-4" />
                        </Button>
                        <Button
                          variant="ghost"
                          size="icon"
                          onClick={() => {
                            setSelectedUser(user);
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

      {/* View User Dialog */}
      <Dialog open={viewDialogOpen} onOpenChange={setViewDialogOpen}>
        <DialogContent className="max-w-2xl max-h-[90vh] overflow-hidden p-0">
          {selectedUser && (
            <>
              {/* Header with Avatar */}
              <div className="bg-gradient-to-r from-blue-600 to-blue-700 px-6 py-8 text-white">
                <div className="flex items-center gap-4">
                  <Avatar className="h-20 w-20 border-4 border-white/20">
                    <AvatarFallback className="bg-white/20 text-white text-2xl font-bold">
                      {selectedUser.profile?.firstName?.charAt(0)}{selectedUser.profile?.lastName?.charAt(0)}
                    </AvatarFallback>
                  </Avatar>
                  <div className="flex-1">
                    <h2 className="text-2xl font-bold">
                      {selectedUser.profile?.firstName} {selectedUser.profile?.lastName}
                    </h2>
                    <div className="flex items-center gap-2 mt-1">
                      <Badge variant="secondary" className="bg-white/20 text-white border-0 capitalize">
                        {selectedUser.role}
                      </Badge>
                      <Badge variant={selectedUser.isActive ? 'default' : 'destructive'} className="bg-white/20 border-0">
                        {selectedUser.isActive ? 'Active' : 'Inactive'}
                      </Badge>
                      {selectedUser.role === 'doctor' && selectedUser.isVerified && (
                        <Badge className="bg-green-500/80 border-0">
                          <Shield className="h-3 w-3 mr-1" />
                          Verified
                        </Badge>
                      )}
                    </div>
                    {selectedUser.role === 'doctor' && selectedUser.profile?.specialty && (
                      <p className="text-blue-100 mt-1">{selectedUser.profile.specialty}</p>
                    )}
                  </div>
                  {selectedUser.role === 'doctor' && selectedUser.profile?.rating && (
                    <div className="text-right">
                      <div className="flex items-center gap-1">
                        <Star className="h-5 w-5 fill-yellow-400 text-yellow-400" />
                        <span className="text-xl font-bold">{selectedUser.profile.rating}</span>
                      </div>
                      <p className="text-sm text-blue-100">{selectedUser.profile.totalReviews} reviews</p>
                    </div>
                  )}
                </div>
              </div>

              {/* Content */}
              <div className="px-6 py-4 overflow-y-auto max-h-[calc(90vh-200px)]">
                {/* Contact Information */}
                <div className="space-y-3">
                  <h4 className="text-sm font-semibold text-muted-foreground uppercase tracking-wide">Contact Information</h4>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                    <div className="flex items-center gap-3 p-3 rounded-lg bg-muted/50">
                      <Mail className="h-5 w-5 text-muted-foreground" />
                      <div>
                        <p className="text-xs text-muted-foreground">Email</p>
                        <p className="text-sm font-medium">{selectedUser.email}</p>
                      </div>
                    </div>
                    <div className="flex items-center gap-3 p-3 rounded-lg bg-muted/50">
                      <Phone className="h-5 w-5 text-muted-foreground" />
                      <div>
                        <p className="text-xs text-muted-foreground">Phone</p>
                        <p className="text-sm font-medium">{selectedUser.profile?.phone || '-'}</p>
                      </div>
                    </div>
                    <div className="flex items-center gap-3 p-3 rounded-lg bg-muted/50">
                      <Calendar className="h-5 w-5 text-muted-foreground" />
                      <div>
                        <p className="text-xs text-muted-foreground">Joined</p>
                        <p className="text-sm font-medium">{new Date(selectedUser.createdAt).toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' })}</p>
                      </div>
                    </div>
                    <div className="flex items-center gap-3 p-3 rounded-lg bg-muted/50">
                      <Shield className="h-5 w-5 text-muted-foreground" />
                      <div>
                        <p className="text-xs text-muted-foreground">Email Verified</p>
                        <p className="text-sm font-medium">{selectedUser.isEmailVerified ? 'Yes' : 'No'}</p>
                      </div>
                    </div>
                  </div>
                </div>

                <Separator className="my-5" />

                {/* Doctor-specific Information */}
                {selectedUser.role === 'doctor' && (
                  <>
                    {/* Professional Details */}
                    <div className="space-y-3">
                      <h4 className="text-sm font-semibold text-muted-foreground uppercase tracking-wide">Professional Details</h4>
                      <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                        <div className="flex items-center gap-3 p-3 rounded-lg bg-muted/50">
                          <Briefcase className="h-5 w-5 text-muted-foreground" />
                          <div>
                            <p className="text-xs text-muted-foreground">Specialty</p>
                            <p className="text-sm font-medium">{selectedUser.profile?.specialty || '-'}</p>
                            {selectedUser.profile?.subSpecialty && (
                              <p className="text-xs text-muted-foreground">{selectedUser.profile.subSpecialty}</p>
                            )}
                          </div>
                        </div>
                        <div className="flex items-center gap-3 p-3 rounded-lg bg-muted/50">
                          <Shield className="h-5 w-5 text-muted-foreground" />
                          <div>
                            <p className="text-xs text-muted-foreground">License Number</p>
                            <p className="text-sm font-medium">{selectedUser.profile?.licenseNumber || '-'}</p>
                          </div>
                        </div>
                        <div className="flex items-center gap-3 p-3 rounded-lg bg-muted/50">
                          <Calendar className="h-5 w-5 text-muted-foreground" />
                          <div>
                            <p className="text-xs text-muted-foreground">Experience</p>
                            <p className="text-sm font-medium">{selectedUser.profile?.yearsOfExperience ? `${selectedUser.profile.yearsOfExperience} years` : '-'}</p>
                          </div>
                        </div>
                        <div className="flex items-center gap-3 p-3 rounded-lg bg-muted/50">
                          <div className="h-5 w-5 text-muted-foreground flex items-center justify-center font-bold text-sm">TND</div>
                          <div>
                            <p className="text-xs text-muted-foreground">Consultation Fee</p>
                            <p className="text-sm font-medium">{selectedUser.profile?.consultationFee ? `${selectedUser.profile.consultationFee} TND` : '-'}</p>
                          </div>
                        </div>
                      </div>

                      {/* Languages */}
                      {selectedUser.profile?.languages && selectedUser.profile.languages.length > 0 && (
                        <div className="mt-3">
                          <p className="text-xs text-muted-foreground mb-2">Languages</p>
                          <div className="flex flex-wrap gap-2">
                            {selectedUser.profile.languages.map((lang, idx) => (
                              <Badge key={idx} variant="outline">{lang}</Badge>
                            ))}
                          </div>
                        </div>
                      )}
                    </div>

                    {/* Education */}
                    {selectedUser.profile?.education && selectedUser.profile.education.length > 0 && (
                      <>
                        <Separator className="my-5" />
                        <div className="space-y-3">
                          <h4 className="text-sm font-semibold text-muted-foreground uppercase tracking-wide">Education</h4>
                          <div className="space-y-2">
                            {selectedUser.profile.education.map((edu, idx) => (
                              <div key={idx} className="flex items-start gap-3 p-3 rounded-lg bg-muted/50">
                                <GraduationCap className="h-5 w-5 text-muted-foreground mt-0.5" />
                                <div>
                                  <p className="text-sm font-medium">{edu.degree}</p>
                                  <p className="text-xs text-muted-foreground">{edu.institution} • {edu.year}</p>
                                </div>
                              </div>
                            ))}
                          </div>
                        </div>
                      </>
                    )}

                    {/* Clinic Information */}
                    {selectedUser.profile?.clinicName && (
                      <>
                        <Separator className="my-5" />
                        <div className="space-y-3">
                          <h4 className="text-sm font-semibold text-muted-foreground uppercase tracking-wide">Clinic</h4>
                          <div className="flex items-start gap-3 p-3 rounded-lg bg-muted/50">
                            <Building className="h-5 w-5 text-muted-foreground mt-0.5" />
                            <div>
                              <p className="text-sm font-medium">{selectedUser.profile.clinicName}</p>
                              {selectedUser.profile.clinicAddress && (
                                <p className="text-xs text-muted-foreground">
                                  {[selectedUser.profile.clinicAddress.street, selectedUser.profile.clinicAddress.city, selectedUser.profile.clinicAddress.country].filter(Boolean).join(', ')}
                                </p>
                              )}
                            </div>
                          </div>
                        </div>
                      </>
                    )}

                    {/* About */}
                    {selectedUser.profile?.about && (
                      <>
                        <Separator className="my-5" />
                        <div className="space-y-3">
                          <h4 className="text-sm font-semibold text-muted-foreground uppercase tracking-wide">About</h4>
                          <p className="text-sm text-muted-foreground leading-relaxed">{selectedUser.profile.about}</p>
                        </div>
                      </>
                    )}
                  </>
                )}

                {/* Patient-specific Information */}
                {selectedUser.role === 'patient' && (
                  <>
                    {/* Personal Details */}
                    <div className="space-y-3">
                      <h4 className="text-sm font-semibold text-muted-foreground uppercase tracking-wide">Personal Details</h4>
                      <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
                        <div className="flex items-center gap-3 p-3 rounded-lg bg-muted/50">
                          <Calendar className="h-5 w-5 text-muted-foreground" />
                          <div>
                            <p className="text-xs text-muted-foreground">Date of Birth</p>
                            <p className="text-sm font-medium">{selectedUser.profile?.dateOfBirth ? new Date(selectedUser.profile.dateOfBirth).toLocaleDateString() : '-'}</p>
                          </div>
                        </div>
                        <div className="flex items-center gap-3 p-3 rounded-lg bg-muted/50">
                          <div className="h-5 w-5 text-muted-foreground flex items-center justify-center">♀♂</div>
                          <div>
                            <p className="text-xs text-muted-foreground">Gender</p>
                            <p className="text-sm font-medium capitalize">{selectedUser.profile?.gender || '-'}</p>
                          </div>
                        </div>
                        <div className="flex items-center gap-3 p-3 rounded-lg bg-muted/50">
                          <Heart className="h-5 w-5 text-red-500" />
                          <div>
                            <p className="text-xs text-muted-foreground">Blood Type</p>
                            <p className="text-sm font-medium">{selectedUser.profile?.bloodType || '-'}</p>
                          </div>
                        </div>
                      </div>
                    </div>

                    {/* Medical Information */}
                    {(selectedUser.profile?.allergies?.length || selectedUser.profile?.chronicConditions?.length) && (
                      <>
                        <Separator className="my-5" />
                        <div className="space-y-3">
                          <h4 className="text-sm font-semibold text-muted-foreground uppercase tracking-wide">Medical Information</h4>
                          {selectedUser.profile?.allergies && selectedUser.profile.allergies.length > 0 && (
                            <div className="p-3 rounded-lg bg-red-50 dark:bg-red-950/20 border border-red-200 dark:border-red-900">
                              <div className="flex items-center gap-2 mb-2">
                                <AlertCircle className="h-4 w-4 text-red-500" />
                                <p className="text-xs font-medium text-red-600 dark:text-red-400">Allergies</p>
                              </div>
                              <div className="flex flex-wrap gap-2">
                                {selectedUser.profile.allergies.map((allergy, idx) => (
                                  <Badge key={idx} variant="destructive" className="bg-red-100 text-red-700 dark:bg-red-900 dark:text-red-300">{allergy}</Badge>
                                ))}
                              </div>
                            </div>
                          )}
                          {selectedUser.profile?.chronicConditions && selectedUser.profile.chronicConditions.length > 0 && (
                            <div className="p-3 rounded-lg bg-orange-50 dark:bg-orange-950/20 border border-orange-200 dark:border-orange-900">
                              <div className="flex items-center gap-2 mb-2">
                                <AlertCircle className="h-4 w-4 text-orange-500" />
                                <p className="text-xs font-medium text-orange-600 dark:text-orange-400">Chronic Conditions</p>
                              </div>
                              <div className="flex flex-wrap gap-2">
                                {selectedUser.profile.chronicConditions.map((condition, idx) => (
                                  <Badge key={idx} variant="outline" className="border-orange-300 text-orange-700 dark:text-orange-300">{condition}</Badge>
                                ))}
                              </div>
                            </div>
                          )}
                        </div>
                      </>
                    )}

                    {/* Emergency Contact */}
                    {selectedUser.profile?.emergencyContact?.name && (
                      <>
                        <Separator className="my-5" />
                        <div className="space-y-3">
                          <h4 className="text-sm font-semibold text-muted-foreground uppercase tracking-wide">Emergency Contact</h4>
                          <div className="flex items-start gap-3 p-3 rounded-lg bg-muted/50">
                            <Phone className="h-5 w-5 text-muted-foreground mt-0.5" />
                            <div>
                              <p className="text-sm font-medium">{selectedUser.profile.emergencyContact.name}</p>
                              <p className="text-xs text-muted-foreground">{selectedUser.profile.emergencyContact.relationship} • {selectedUser.profile.emergencyContact.phone}</p>
                            </div>
                          </div>
                        </div>
                      </>
                    )}

                    {/* Address */}
                    {selectedUser.profile?.address?.city && (
                      <>
                        <Separator className="my-5" />
                        <div className="space-y-3">
                          <h4 className="text-sm font-semibold text-muted-foreground uppercase tracking-wide">Address</h4>
                          <div className="flex items-start gap-3 p-3 rounded-lg bg-muted/50">
                            <MapPin className="h-5 w-5 text-muted-foreground mt-0.5" />
                            <div>
                              <p className="text-sm font-medium">
                                {[selectedUser.profile.address.street, selectedUser.profile.address.city, selectedUser.profile.address.state, selectedUser.profile.address.country].filter(Boolean).join(', ')}
                              </p>
                              {selectedUser.profile.address.zipCode && (
                                <p className="text-xs text-muted-foreground">{selectedUser.profile.address.zipCode}</p>
                              )}
                            </div>
                          </div>
                        </div>
                      </>
                    )}
                  </>
                )}
              </div>

              {/* Footer */}
              <div className="border-t px-6 py-4 flex justify-end gap-2">
                <Button variant="outline" onClick={() => setViewDialogOpen(false)}>
                  Close
                </Button>
                <Button
                  variant={selectedUser.isActive ? 'destructive' : 'default'}
                  onClick={() => {
                    setViewDialogOpen(false);
                    handleStatusChange(selectedUser);
                  }}
                >
                  {selectedUser.isActive ? 'Deactivate User' : 'Activate User'}
                </Button>
              </div>
            </>
          )}
        </DialogContent>
      </Dialog>

      {/* Status Change Dialog */}
      <Dialog open={statusDialogOpen} onOpenChange={setStatusDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>
              {selectedUser?.isActive ? 'Deactivate User' : 'Activate User'}
            </DialogTitle>
            <DialogDescription>
              {selectedUser?.isActive
                ? 'This will prevent the user from accessing the platform.'
                : 'This will allow the user to access the platform.'}
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4">
            <div>
              <Label htmlFor="reason">Reason (Optional)</Label>
              <Textarea
                id="reason"
                placeholder="Provide a reason for this action..."
                value={statusReason}
                onChange={(e) => setStatusReason(e.target.value)}
              />
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setStatusDialogOpen(false)}>
              Cancel
            </Button>
            <Button
              variant={selectedUser?.isActive ? 'destructive' : 'default'}
              onClick={handleStatusChange}
              disabled={actionLoading}
            >
              {actionLoading ? 'Processing...' : selectedUser?.isActive ? 'Deactivate' : 'Activate'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Delete Confirmation Dialog */}
      <AlertDialog open={deleteDialogOpen} onOpenChange={setDeleteDialogOpen}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Are you sure?</AlertDialogTitle>
            <AlertDialogDescription>
              This action cannot be undone. This will permanently delete the user{' '}
              {selectedUser?.profile?.firstName} {selectedUser?.profile?.lastName}.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancel</AlertDialogCancel>
            <AlertDialogAction
              onClick={handleDeleteUser}
              disabled={actionLoading}
              className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
            >
              {actionLoading ? 'Deleting...' : 'Delete'}
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}
