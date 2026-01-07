'use client';

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Label } from '@/components/ui/label';
import { Switch } from '@/components/ui/switch';
import { Separator } from '@/components/ui/separator';
import { Settings, Bell, Shield, Palette, Database, Globe } from 'lucide-react';
import { useTheme } from 'next-themes';

export default function SettingsPage() {
  const { theme, setTheme } = useTheme();

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-3xl font-bold tracking-tight">Settings</h1>
        <p className="text-muted-foreground">
          Manage your admin dashboard preferences
        </p>
      </div>

      {/* Appearance Settings */}
      <Card>
        <CardHeader>
          <div className="flex items-center gap-3">
            <div className="p-2 bg-purple-100 dark:bg-purple-900 rounded-lg">
              <Palette className="h-6 w-6 text-purple-600 dark:text-purple-400" />
            </div>
            <div>
              <CardTitle>Appearance</CardTitle>
              <CardDescription>
                Customize the look and feel
              </CardDescription>
            </div>
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="flex items-center justify-between">
            <div>
              <Label>Dark Mode</Label>
              <p className="text-sm text-muted-foreground">
                Switch between light and dark themes
              </p>
            </div>
            <Switch
              checked={theme === 'dark'}
              onCheckedChange={(checked) => setTheme(checked ? 'dark' : 'light')}
            />
          </div>
          <Separator />
          <div>
            <Label>Theme Preview</Label>
            <p className="text-sm text-muted-foreground mt-1">
              Current theme: <strong className="capitalize">{theme}</strong>
            </p>
          </div>
        </CardContent>
      </Card>

      {/* Notification Settings */}
      <Card>
        <CardHeader>
          <div className="flex items-center gap-3">
            <div className="p-2 bg-blue-100 dark:bg-blue-900 rounded-lg">
              <Bell className="h-6 w-6 text-blue-600 dark:text-blue-400" />
            </div>
            <div>
              <CardTitle>Notifications</CardTitle>
              <CardDescription>
                Manage notification preferences
              </CardDescription>
            </div>
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="flex items-center justify-between">
            <div>
              <Label>Email Notifications</Label>
              <p className="text-sm text-muted-foreground">
                Receive email updates for important events
              </p>
            </div>
            <Switch defaultChecked />
          </div>
          <Separator />
          <div className="flex items-center justify-between">
            <div>
              <Label>Push Notifications</Label>
              <p className="text-sm text-muted-foreground">
                Receive browser push notifications
              </p>
            </div>
            <Switch defaultChecked />
          </div>
          <Separator />
          <div className="flex items-center justify-between">
            <div>
              <Label>Sound Alerts</Label>
              <p className="text-sm text-muted-foreground">
                Play sound for new notifications
              </p>
            </div>
            <Switch />
          </div>
        </CardContent>
      </Card>

      {/* Security Settings */}
      <Card>
        <CardHeader>
          <div className="flex items-center gap-3">
            <div className="p-2 bg-green-100 dark:bg-green-900 rounded-lg">
              <Shield className="h-6 w-6 text-green-600 dark:text-green-400" />
            </div>
            <div>
              <CardTitle>Security</CardTitle>
              <CardDescription>
                Manage security settings
              </CardDescription>
            </div>
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="flex items-center justify-between">
            <div>
              <Label>Two-Factor Authentication</Label>
              <p className="text-sm text-muted-foreground">
                Add an extra layer of security
              </p>
            </div>
            <Switch />
          </div>
          <Separator />
          <div>
            <Label>Session Timeout</Label>
            <p className="text-sm text-muted-foreground mt-1">
              Automatically logout after inactivity
            </p>
          </div>
          <div className="mt-2">
            <select className="w-full p-2 border rounded-md bg-background">
              <option value="15">15 minutes</option>
              <option value="30" selected>30 minutes</option>
              <option value="60">1 hour</option>
              <option value="0">Never</option>
            </select>
          </div>
        </CardContent>
      </Card>

      {/* Data Settings */}
      <Card>
        <CardHeader>
          <div className="flex items-center gap-3">
            <div className="p-2 bg-orange-100 dark:bg-orange-900 rounded-lg">
              <Database className="h-6 w-6 text-orange-600 dark:text-orange-400" />
            </div>
            <div>
              <CardTitle>Data & Privacy</CardTitle>
              <CardDescription>
                Manage your data and privacy settings
              </CardDescription>
            </div>
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          <Button variant="outline" className="w-full justify-start">
            <Database className="mr-2 h-4 w-4" />
            Export Audit Logs
          </Button>
          <Button variant="outline" className="w-full justify-start">
            <Database className="mr-2 h-4 w-4" />
            Generate Compliance Report
          </Button>
          <Separator />
          <div>
            <Label>Auto-refresh</Label>
            <p className="text-sm text-muted-foreground mt-1">
              Automatically refresh data every
            </p>
          </div>
          <div className="mt-2">
            <select className="w-full p-2 border rounded-md bg-background">
              <option value="30">30 seconds</option>
              <option value="60" selected>1 minute</option>
              <option value="300">5 minutes</option>
              <option value="0">Disabled</option>
            </select>
          </div>
        </CardContent>
      </Card>

      {/* Region Settings */}
      <Card>
        <CardHeader>
          <div className="flex items-center gap-3">
            <div className="p-2 bg-cyan-100 dark:bg-cyan-900 rounded-lg">
              <Globe className="h-6 w-6 text-cyan-600 dark:text-cyan-400" />
            </div>
            <div>
              <CardTitle>Regional Settings</CardTitle>
              <CardDescription>
                Configure regional preferences
              </CardDescription>
            </div>
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          <div>
            <Label>Timezone</Label>
            <p className="text-sm text-muted-foreground mt-1">
              Your current timezone
            </p>
          </div>
          <div className="mt-2">
            <select className="w-full p-2 border rounded-md bg-background">
              <option value="UTC">UTC (Coordinated Universal Time)</option>
              <option value="Europe/Tunis">Africa/Tunis</option>
              <option value="Europe/Paris">Europe/Paris</option>
              <option value="America/New_York">America/New_York</option>
            </select>
          </div>
          <Separator />
          <div>
            <Label>Language</Label>
            <p className="text-sm text-muted-foreground mt-1">
              Dashboard interface language
            </p>
          </div>
          <div className="mt-2">
            <select className="w-full p-2 border rounded-md bg-background">
              <option value="en" selected>English</option>
              <option value="fr">Français</option>
              <option value="ar">العربية</option>
            </select>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
