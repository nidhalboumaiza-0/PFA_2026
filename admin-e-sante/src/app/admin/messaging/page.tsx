'use client';

import { useEffect, useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { MessageSquare, Users, Activity, TrendingUp } from 'lucide-react';
import { messagingService } from '@/lib/api';
import { toast } from '@/hooks/use-toast';
import { Skeleton } from '@/components/ui/skeleton';

export default function MessagingPage() {
  const [stats, setStats] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchStats();
  }, []);

  const fetchStats = async () => {
    try {
      setLoading(true);
      const data = await messagingService.getStats();
      setStats(data);
    } catch (error: any) {
      toast({
        title: 'Error',
        description: error.message || 'Failed to fetch messaging stats',
        variant: 'destructive',
      });
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="space-y-6">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Messaging</h1>
          <p className="text-muted-foreground">
            Overview of platform messaging activity
          </p>
        </div>
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
          {[1, 2, 3, 4].map((i) => (
            <Card key={i}>
              <CardHeader>
                <Skeleton className="h-4 w-24" />
                <Skeleton className="h-8 w-20" />
              </CardHeader>
            </Card>
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-3xl font-bold tracking-tight">Messaging</h1>
        <p className="text-muted-foreground">
          Overview of platform messaging activity
        </p>
      </div>

      {/* Overview Stats */}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">
              Total Conversations
            </CardTitle>
            <MessageSquare className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {stats?.overview?.totalConversations || 0}
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">
              Total Messages
            </CardTitle>
            <Activity className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {stats?.overview?.totalMessages?.toLocaleString() || 0}
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">
              Active Conversations
            </CardTitle>
            <Users className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {stats?.overview?.activeConversations || 0}
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">
              Unique Participants
            </CardTitle>
            <TrendingUp className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {stats?.overview?.uniqueParticipants || 0}
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Period Stats */}
      <Card>
        <CardHeader>
          <CardTitle>Messaging Activity</CardTitle>
          <CardDescription>
            Message volume by time period
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid gap-4 md:grid-cols-3">
            <div className="p-4 border rounded-lg">
              <p className="text-sm font-medium text-muted-foreground">Today</p>
              <p className="text-2xl font-bold">
                {stats?.period?.today?.messages || 0}
              </p>
              <p className="text-xs text-muted-foreground mt-1">
                +{stats?.period?.today?.newConversations || 0} new conversations
              </p>
            </div>
            <div className="p-4 border rounded-lg">
              <p className="text-sm font-medium text-muted-foreground">This Week</p>
              <p className="text-2xl font-bold">
                {stats?.period?.thisWeek?.messages || 0}
              </p>
              <p className="text-xs text-muted-foreground mt-1">
                +{stats?.period?.thisWeek?.newConversations || 0} new conversations
              </p>
            </div>
            <div className="p-4 border rounded-lg">
              <p className="text-sm font-medium text-muted-foreground">This Month</p>
              <p className="text-2xl font-bold">
                {stats?.period?.thisMonth?.messages || 0}
              </p>
              <p className="text-xs text-muted-foreground mt-1">
                +{stats?.period?.thisMonth?.newConversations || 0} new conversations
              </p>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Top Participants */}
      <Card>
        <CardHeader>
          <CardTitle>Top Participants</CardTitle>
          <CardDescription>
            Most active message senders
          </CardDescription>
        </CardHeader>
        <CardContent>
          {stats?.topParticipants && stats.topParticipants.length > 0 ? (
            <div className="space-y-2">
              {stats.topParticipants.map((participant: any, index: number) => (
                <div key={participant.userId} className="flex items-center justify-between p-3 border rounded-lg">
                  <div className="flex items-center gap-3">
                    <div className="w-8 h-8 bg-blue-100 dark:bg-blue-900 rounded-full flex items-center justify-center text-blue-600 dark:text-blue-400 font-medium">
                      {index + 1}
                    </div>
                    <div>
                      <p className="font-medium">{participant.name}</p>
                    </div>
                  </div>
                  <div className="text-right">
                    <p className="text-2xl font-bold">{participant.messageCount}</p>
                    <p className="text-xs text-muted-foreground">messages</p>
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <p className="text-sm text-muted-foreground text-center py-8">
              No messaging activity yet
            </p>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
