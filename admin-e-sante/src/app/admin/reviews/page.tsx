'use client';

import { useEffect, useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Progress } from '@/components/ui/progress';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { 
  MessageSquare, 
  Star, 
  Trash2, 
  ChevronLeft, 
  ChevronRight,
  Loader2,
  AlertCircle,
  TrendingUp,
  TrendingDown,
  Users,
  BarChart3,
  MessageCircle,
  ThumbsUp,
  ThumbsDown,
  Calendar,
  Eye
} from 'lucide-react';
import { reviewsService, AdminReviewsResponse, AdvancedStatsResponse, DoctorReviewStats } from '@/lib/api';
import { format } from 'date-fns';
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from '@/components/ui/alert-dialog';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";

export default function ReviewsPage() {
  const [reviewsData, setReviewsData] = useState<AdminReviewsResponse | null>(null);
  const [advancedStats, setAdvancedStats] = useState<AdvancedStatsResponse | null>(null);
  const [loading, setLoading] = useState(true);
  const [statsLoading, setStatsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [currentPage, setCurrentPage] = useState(1);
  const [filterRating, setFilterRating] = useState<number | null>(null);
  const [filterDoctor, setFilterDoctor] = useState<string | null>(null);
  const [deletingId, setDeletingId] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState('overview');

  const fetchAdvancedStats = async () => {
    setStatsLoading(true);
    try {
      const data = await reviewsService.getAdvancedStats();
      setAdvancedStats(data);
    } catch (err: any) {
      console.error('Failed to fetch advanced stats:', err);
    } finally {
      setStatsLoading(false);
    }
  };

  const fetchReviews = async (page: number = 1, rating?: number, doctorId?: string) => {
    setLoading(true);
    setError(null);
    try {
      const data = await reviewsService.getAllReviews(page, 10, rating || undefined, doctorId || undefined);
      setReviewsData(data);
    } catch (err: any) {
      console.error('Failed to fetch reviews:', err);
      setError(err.message || 'Failed to load reviews');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchAdvancedStats();
  }, []);

  useEffect(() => {
    fetchReviews(currentPage, filterRating || undefined, filterDoctor || undefined);
  }, [currentPage, filterRating, filterDoctor]);

  const handleDelete = async (reviewId: string) => {
    setDeletingId(reviewId);
    try {
      await reviewsService.deleteReview(reviewId);
      fetchReviews(currentPage, filterRating || undefined, filterDoctor || undefined);
      fetchAdvancedStats();
    } catch (err: any) {
      console.error('Failed to delete review:', err);
      setError(err.message || 'Failed to delete review');
    } finally {
      setDeletingId(null);
    }
  };

  const renderStars = (rating: number, size: 'sm' | 'md' = 'sm') => {
    const sizeClass = size === 'sm' ? 'h-4 w-4' : 'h-5 w-5';
    return (
      <div className="flex gap-0.5">
        {[1, 2, 3, 4, 5].map((star) => (
          <Star
            key={star}
            className={`${sizeClass} ${
              star <= rating
                ? 'fill-yellow-400 text-yellow-400'
                : 'text-gray-300'
            }`}
          />
        ))}
      </div>
    );
  };

  const getRatingColor = (rating: number) => {
    if (rating >= 4) return 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300';
    if (rating >= 3) return 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-300';
    return 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300';
  };

  const handleDoctorSelect = (doctorId: string) => {
    setFilterDoctor(doctorId);
    setCurrentPage(1);
    setActiveTab('reviews');
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-3xl font-bold tracking-tight">Reviews</h1>
        <p className="text-muted-foreground">
          View and moderate patient reviews for doctors
        </p>
      </div>

      <Tabs value={activeTab} onValueChange={setActiveTab}>
        <TabsList className="grid w-full grid-cols-3">
          <TabsTrigger value="overview" className="flex items-center gap-2">
            <BarChart3 className="h-4 w-4" />
            Overview
          </TabsTrigger>
          <TabsTrigger value="doctors" className="flex items-center gap-2">
            <Users className="h-4 w-4" />
            Per Doctor
          </TabsTrigger>
          <TabsTrigger value="reviews" className="flex items-center gap-2">
            <MessageSquare className="h-4 w-4" />
            All Reviews
          </TabsTrigger>
        </TabsList>

        {/* Overview Tab */}
        <TabsContent value="overview" className="space-y-6">
          {statsLoading ? (
            <div className="flex items-center justify-center py-12">
              <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
            </div>
          ) : advancedStats ? (
            <>
              {/* Key Metrics */}
              <div className="grid gap-4 md:grid-cols-4">
                <Card>
                  <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                    <CardTitle className="text-sm font-medium">Total Reviews</CardTitle>
                    <MessageSquare className="h-4 w-4 text-muted-foreground" />
                  </CardHeader>
                  <CardContent>
                    <div className="text-2xl font-bold">{advancedStats.overall.totalReviews}</div>
                    <p className="text-xs text-muted-foreground">
                      {advancedStats.overall.totalWithComments} with comments ({advancedStats.overall.commentRate}%)
                    </p>
                  </CardContent>
                </Card>
                
                <Card>
                  <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                    <CardTitle className="text-sm font-medium">Average Rating</CardTitle>
                    <Star className="h-4 w-4 text-yellow-500" />
                  </CardHeader>
                  <CardContent>
                    <div className="text-2xl font-bold flex items-center gap-2">
                      {advancedStats.overall.averageRating.toFixed(1)}
                      {renderStars(Math.round(advancedStats.overall.averageRating))}
                    </div>
                  </CardContent>
                </Card>

                <Card>
                  <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                    <CardTitle className="text-sm font-medium">Positive (4-5★)</CardTitle>
                    <ThumbsUp className="h-4 w-4 text-green-500" />
                  </CardHeader>
                  <CardContent>
                    <div className="text-2xl font-bold text-green-600">{advancedStats.overall.positiveRate}%</div>
                    <p className="text-xs text-muted-foreground">
                      {advancedStats.overall.distribution[5] + advancedStats.overall.distribution[4]} reviews
                    </p>
                  </CardContent>
                </Card>

                <Card>
                  <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                    <CardTitle className="text-sm font-medium">Negative (1-2★)</CardTitle>
                    <ThumbsDown className="h-4 w-4 text-red-500" />
                  </CardHeader>
                  <CardContent>
                    <div className="text-2xl font-bold text-red-600">{advancedStats.overall.negativeRate}%</div>
                    <p className="text-xs text-muted-foreground">
                      {advancedStats.overall.distribution[1] + advancedStats.overall.distribution[2]} reviews
                    </p>
                  </CardContent>
                </Card>
              </div>

              {/* Rating Distribution */}
              <Card>
                <CardHeader>
                  <CardTitle>Rating Distribution</CardTitle>
                  <CardDescription>Breakdown of all reviews by star rating</CardDescription>
                </CardHeader>
                <CardContent className="space-y-3">
                  {[5, 4, 3, 2, 1].map((star) => {
                    const count = advancedStats.overall.distribution[star as keyof typeof advancedStats.overall.distribution];
                    const percentage = advancedStats.overall.totalReviews > 0 
                      ? (count / advancedStats.overall.totalReviews) * 100 
                      : 0;
                    return (
                      <div key={star} className="flex items-center gap-3">
                        <div className="flex items-center gap-1 min-w-[60px]">
                          <span>{star}</span>
                          <Star className="h-4 w-4 fill-yellow-400 text-yellow-400" />
                        </div>
                        <Progress value={percentage} className="flex-1" />
                        <span className="text-sm text-muted-foreground min-w-[80px] text-right">
                          {count} ({percentage.toFixed(0)}%)
                        </span>
                      </div>
                    );
                  })}
                </CardContent>
              </Card>

              {/* Top & Lowest Rated */}
              <div className="grid gap-4 md:grid-cols-2">
                <Card>
                  <CardHeader>
                    <CardTitle className="flex items-center gap-2">
                      <TrendingUp className="h-5 w-5 text-green-500" />
                      Top Rated Doctors
                    </CardTitle>
                    <CardDescription>Doctors with highest average ratings</CardDescription>
                  </CardHeader>
                  <CardContent>
                    {advancedStats.topRatedDoctors.length === 0 ? (
                      <p className="text-sm text-muted-foreground">No data yet</p>
                    ) : (
                      <div className="space-y-3">
                        {advancedStats.topRatedDoctors.map((doctor, idx) => (
                          <div key={doctor.doctorId} className="flex items-center justify-between">
                            <div className="flex items-center gap-3">
                              <span className="text-sm font-medium text-muted-foreground w-6">#{idx + 1}</span>
                              <Button
                                variant="link"
                                className="p-0 h-auto text-sm"
                                onClick={() => handleDoctorSelect(doctor.doctorId)}
                              >
                                Doctor {doctor.doctorId.slice(-6)}
                              </Button>
                            </div>
                            <div className="flex items-center gap-2">
                              {renderStars(Math.round(doctor.averageRating))}
                              <Badge variant="secondary">{doctor.averageRating}</Badge>
                              <span className="text-xs text-muted-foreground">({doctor.totalReviews})</span>
                            </div>
                          </div>
                        ))}
                      </div>
                    )}
                  </CardContent>
                </Card>

                <Card>
                  <CardHeader>
                    <CardTitle className="flex items-center gap-2">
                      <TrendingDown className="h-5 w-5 text-red-500" />
                      Needs Attention
                    </CardTitle>
                    <CardDescription>Doctors with lowest ratings (may need review)</CardDescription>
                  </CardHeader>
                  <CardContent>
                    {advancedStats.lowestRatedDoctors.length === 0 ? (
                      <p className="text-sm text-muted-foreground">No data yet</p>
                    ) : (
                      <div className="space-y-3">
                        {advancedStats.lowestRatedDoctors.map((doctor) => (
                          <div key={doctor.doctorId} className="flex items-center justify-between">
                            <Button
                              variant="link"
                              className="p-0 h-auto text-sm"
                              onClick={() => handleDoctorSelect(doctor.doctorId)}
                            >
                              Doctor {doctor.doctorId.slice(-6)}
                            </Button>
                            <div className="flex items-center gap-2">
                              {renderStars(Math.round(doctor.averageRating))}
                              <Badge variant="destructive">{doctor.averageRating}</Badge>
                              <span className="text-xs text-muted-foreground">({doctor.totalReviews})</span>
                            </div>
                          </div>
                        ))}
                      </div>
                    )}
                  </CardContent>
                </Card>
              </div>

              {/* Recent Reviews */}
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center gap-2">
                    <Calendar className="h-5 w-5" />
                    Recent Reviews
                  </CardTitle>
                  <CardDescription>Latest submitted reviews</CardDescription>
                </CardHeader>
                <CardContent>
                  {advancedStats.recentReviews.length === 0 ? (
                    <p className="text-sm text-muted-foreground">No reviews yet</p>
                  ) : (
                    <div className="space-y-3">
                      {advancedStats.recentReviews.map((review) => (
                        <div key={review._id} className="flex items-start justify-between border-b pb-3 last:border-0">
                          <div className="space-y-1">
                            <div className="flex items-center gap-2">
                              {renderStars(review.rating)}
                              <span className="text-xs text-muted-foreground">
                                {format(new Date(review.createdAt), 'MMM d, yyyy HH:mm')}
                              </span>
                            </div>
                            {review.comment && (
                              <p className="text-sm text-muted-foreground line-clamp-1">{review.comment}</p>
                            )}
                          </div>
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => handleDoctorSelect(review.doctorId)}
                          >
                            <Eye className="h-4 w-4" />
                          </Button>
                        </div>
                      ))}
                    </div>
                  )}
                </CardContent>
              </Card>
            </>
          ) : (
            <div className="flex flex-col items-center justify-center py-12 text-muted-foreground">
              <MessageSquare className="h-12 w-12 mb-4" />
              <p>No statistics available</p>
            </div>
          )}
        </TabsContent>

        {/* Per Doctor Tab */}
        <TabsContent value="doctors" className="space-y-6">
          {statsLoading ? (
            <div className="flex items-center justify-center py-12">
              <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
            </div>
          ) : advancedStats && advancedStats.doctorStats.length > 0 ? (
            <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
              {advancedStats.doctorStats.map((doctor) => (
                <Card key={doctor.doctorId} className="hover:shadow-md transition-shadow">
                  <CardHeader className="pb-2">
                    <div className="flex items-center justify-between">
                      <CardTitle className="text-base">Doctor {doctor.doctorId.slice(-6)}</CardTitle>
                      <Badge className={getRatingColor(doctor.averageRating)}>
                        {doctor.averageRating} ★
                      </Badge>
                    </div>
                    <CardDescription className="flex items-center gap-1">
                      {renderStars(Math.round(doctor.averageRating))}
                      <span className="ml-2">({doctor.totalReviews} reviews)</span>
                    </CardDescription>
                  </CardHeader>
                  <CardContent className="space-y-3">
                    {/* Mini distribution */}
                    <div className="space-y-1">
                      {[5, 4, 3, 2, 1].map((star) => {
                        const count = doctor.distribution[star as keyof typeof doctor.distribution];
                        const percentage = doctor.totalReviews > 0 
                          ? (count / doctor.totalReviews) * 100 
                          : 0;
                        return (
                          <div key={star} className="flex items-center gap-2 text-xs">
                            <span className="w-3">{star}★</span>
                            <Progress value={percentage} className="h-2 flex-1" />
                            <span className="w-6 text-right text-muted-foreground">{count}</span>
                          </div>
                        );
                      })}
                    </div>

                    <div className="flex items-center justify-between text-xs text-muted-foreground pt-2 border-t">
                      <span className="flex items-center gap-1">
                        <MessageCircle className="h-3 w-3" />
                        {doctor.totalWithComments} with comments
                      </span>
                      <span>
                        Latest: {format(new Date(doctor.latestReview), 'MMM d')}
                      </span>
                    </div>

                    <Button 
                      variant="outline" 
                      size="sm" 
                      className="w-full"
                      onClick={() => handleDoctorSelect(doctor.doctorId)}
                    >
                      View Reviews
                    </Button>
                  </CardContent>
                </Card>
              ))}
            </div>
          ) : (
            <div className="flex flex-col items-center justify-center py-12 text-muted-foreground">
              <Users className="h-12 w-12 mb-4" />
              <p className="text-lg font-medium">No doctor reviews yet</p>
              <p className="text-sm">Reviews will appear here when patients submit them</p>
            </div>
          )}
        </TabsContent>

        {/* All Reviews Tab */}
        <TabsContent value="reviews" className="space-y-6">
          {/* Filters */}
          <Card>
            <CardHeader className="pb-3">
              <CardTitle className="text-base">Filters</CardTitle>
            </CardHeader>
            <CardContent className="flex flex-wrap gap-4">
              <div className="flex items-center gap-2">
                <span className="text-sm text-muted-foreground">Rating:</span>
                <Select 
                  value={filterRating?.toString() || 'all'} 
                  onValueChange={(v) => {
                    setFilterRating(v === 'all' ? null : parseInt(v));
                    setCurrentPage(1);
                  }}
                >
                  <SelectTrigger className="w-[120px]">
                    <SelectValue placeholder="All ratings" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">All ratings</SelectItem>
                    <SelectItem value="5">5 stars</SelectItem>
                    <SelectItem value="4">4 stars</SelectItem>
                    <SelectItem value="3">3 stars</SelectItem>
                    <SelectItem value="2">2 stars</SelectItem>
                    <SelectItem value="1">1 star</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              {advancedStats && advancedStats.doctorStats.length > 0 && (
                <div className="flex items-center gap-2">
                  <span className="text-sm text-muted-foreground">Doctor:</span>
                  <Select 
                    value={filterDoctor || 'all'} 
                    onValueChange={(v) => {
                      setFilterDoctor(v === 'all' ? null : v);
                      setCurrentPage(1);
                    }}
                  >
                    <SelectTrigger className="w-[180px]">
                      <SelectValue placeholder="All doctors" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="all">All doctors</SelectItem>
                      {advancedStats.doctorStats.map((d) => (
                        <SelectItem key={d.doctorId} value={d.doctorId}>
                          Doctor {d.doctorId.slice(-6)} ({d.totalReviews})
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
              )}

              {(filterRating || filterDoctor) && (
                <Button 
                  variant="ghost" 
                  size="sm"
                  onClick={() => {
                    setFilterRating(null);
                    setFilterDoctor(null);
                    setCurrentPage(1);
                  }}
                >
                  Clear filters
                </Button>
              )}
            </CardContent>
          </Card>

          {/* Reviews List */}
          <Card>
            <CardHeader>
              <div className="flex items-center justify-between">
                <div>
                  <CardTitle>Reviews</CardTitle>
                  <CardDescription>
                    {reviewsData?.pagination.totalReviews || 0} total reviews
                    {filterDoctor && ` for Doctor ${filterDoctor.slice(-6)}`}
                  </CardDescription>
                </div>
              </div>
            </CardHeader>
            <CardContent>
              {loading ? (
                <div className="flex items-center justify-center py-8">
                  <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
                </div>
              ) : error ? (
                <div className="flex flex-col items-center justify-center py-8 text-red-500">
                  <AlertCircle className="h-8 w-8 mb-2" />
                  <p>{error}</p>
                  <Button 
                    variant="outline" 
                    className="mt-4"
                    onClick={() => fetchReviews(currentPage, filterRating || undefined, filterDoctor || undefined)}
                  >
                    Retry
                  </Button>
                </div>
              ) : reviewsData?.reviews.length === 0 ? (
                <div className="flex flex-col items-center justify-center py-8 text-muted-foreground">
                  <MessageSquare className="h-12 w-12 mb-4" />
                  <p className="text-lg font-medium">No reviews found</p>
                  <p className="text-sm">
                    {filterRating || filterDoctor 
                      ? 'Try adjusting your filters'
                      : 'Reviews will appear here when patients submit them'}
                  </p>
                </div>
              ) : (
                <div className="space-y-4">
                  {reviewsData?.reviews.map((review) => (
                    <div
                      key={review._id}
                      className="border rounded-lg p-4 space-y-3"
                    >
                      <div className="flex items-start justify-between">
                        <div className="flex items-center gap-3">
                          {renderStars(review.rating)}
                          <Badge className={getRatingColor(review.rating)}>
                            {review.rating}/5
                          </Badge>
                        </div>
                        <div className="flex items-center gap-2">
                          <span className="text-sm text-muted-foreground">
                            {format(new Date(review.createdAt), 'MMM d, yyyy HH:mm')}
                          </span>
                          <AlertDialog>
                            <AlertDialogTrigger asChild>
                              <Button 
                                variant="ghost" 
                                size="icon"
                                disabled={deletingId === review._id}
                              >
                                {deletingId === review._id ? (
                                  <Loader2 className="h-4 w-4 animate-spin" />
                                ) : (
                                  <Trash2 className="h-4 w-4 text-red-500" />
                                )}
                              </Button>
                            </AlertDialogTrigger>
                            <AlertDialogContent>
                              <AlertDialogHeader>
                                <AlertDialogTitle>Delete Review</AlertDialogTitle>
                                <AlertDialogDescription>
                                  Are you sure you want to delete this review? This action cannot be undone.
                                </AlertDialogDescription>
                              </AlertDialogHeader>
                              <AlertDialogFooter>
                                <AlertDialogCancel>Cancel</AlertDialogCancel>
                                <AlertDialogAction
                                  onClick={() => handleDelete(review._id)}
                                  className="bg-red-600 hover:bg-red-700"
                                >
                                  Delete
                                </AlertDialogAction>
                              </AlertDialogFooter>
                            </AlertDialogContent>
                          </AlertDialog>
                        </div>
                      </div>
                      
                      {review.comment ? (
                        <p className="text-sm">{review.comment}</p>
                      ) : (
                        <p className="text-sm text-muted-foreground italic">No comment provided</p>
                      )}

                      <div className="flex gap-4 text-xs text-muted-foreground">
                        <span>Doctor: {review.doctorId.slice(-6)}</span>
                        <span>Patient: {review.patientId.slice(-6)}</span>
                        <span>Appointment: {review.appointmentId.slice(-6)}</span>
                      </div>
                    </div>
                  ))}

                  {/* Pagination */}
                  {reviewsData && reviewsData.pagination.totalPages > 1 && (
                    <div className="flex items-center justify-between pt-4">
                      <p className="text-sm text-muted-foreground">
                        Page {reviewsData.pagination.currentPage} of {reviewsData.pagination.totalPages}
                      </p>
                      <div className="flex gap-2">
                        <Button
                          variant="outline"
                          size="sm"
                          onClick={() => setCurrentPage(p => Math.max(1, p - 1))}
                          disabled={currentPage === 1}
                        >
                          <ChevronLeft className="h-4 w-4" />
                          Previous
                        </Button>
                        <Button
                          variant="outline"
                          size="sm"
                          onClick={() => setCurrentPage(p => p + 1)}
                          disabled={!reviewsData.pagination.hasMore}
                        >
                          Next
                          <ChevronRight className="h-4 w-4" />
                        </Button>
                      </div>
                    </div>
                  )}
                </div>
              )}
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}
