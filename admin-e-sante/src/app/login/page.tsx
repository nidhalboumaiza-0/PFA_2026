'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card';
import { useAuth } from '@/components/providers/auth-provider';
import { Loader2, Heart, Shield, Lock, Mail, ArrowRight, CheckCircle2 } from 'lucide-react';

const loginSchema = z.object({
  email: z.string().email('Invalid email address'),
  password: z.string().min(6, 'Password must be at least 6 characters'),
});

type LoginFormData = z.infer<typeof loginSchema>;

export default function LoginPage() {
  const router = useRouter();
  const { login } = useAuth();
  const [isLoading, setIsLoading] = useState(false);

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<LoginFormData>({
    resolver: zodResolver(loginSchema),
  });

  const onSubmit = async (data: LoginFormData) => {
    setIsLoading(true);
    try {
      await login(data.email, data.password);
      // Navigation is handled in the login function
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen relative overflow-hidden flex items-center justify-center bg-gradient-to-br from-blue-50 via-white to-cyan-50 dark:from-gray-900 dark:via-gray-800 dark:to-gray-900 p-4">
      {/* Animated Background Pattern */}
      <div className="absolute inset-0 overflow-hidden pointer-events-none">
        <div className="absolute top-20 left-20 w-64 h-64 bg-blue-200 dark:bg-blue-900 rounded-full opacity-20 animate-pulse" />
        <div className="absolute bottom-20 right-20 w-96 h-96 bg-cyan-200 dark:bg-cyan-900 rounded-full opacity-20 animate-pulse delay-1000" />
        <div className="absolute top-1/2 left-1/4 w-32 h-32 bg-purple-200 dark:bg-purple-900 rounded-full opacity-10 animate-pulse delay-500" />
        <div className="absolute top-1/4 right-1/4 w-48 h-48 bg-green-200 dark:bg-green-900 rounded-full opacity-10 animate-pulse delay-1500" />
      </div>

      {/* Main Card */}
      <div className="relative z-10 w-full max-w-md">
        <Card className="shadow-2xl border-0 bg-white/95 dark:bg-gray-900/95 backdrop-blur-xl">
          {/* Header Section */}
          <CardHeader className="space-y-6 pb-8">
            {/* Logo with Glow Effect */}
            <div className="flex flex-col items-center justify-center space-y-4">
              <div className="relative group">
                <div className="absolute inset-0 bg-gradient-to-r from-blue-600 to-cyan-500 rounded-full blur-xl opacity-50 group-hover:opacity-80 transition-all duration-500 animate-pulse" />
                <div className="relative flex items-center justify-center w-20 h-20 bg-gradient-to-br from-blue-600 to-blue-700 dark:from-blue-500 dark:to-blue-600 rounded-full shadow-xl shadow-blue-500/30">
                  <Heart className="w-10 h-10 text-white drop-shadow-lg" />
                  <div className="absolute -top-1 -right-1 w-5 h-5 bg-green-400 dark:bg-green-500 rounded-full flex items-center justify-center">
                    <CheckCircle2 className="w-3 h-3 text-white" />
                  </div>
                </div>
              </div>

              <div className="text-center space-y-2">
                <CardTitle className="text-3xl font-bold tracking-tight bg-gradient-to-r from-blue-600 to-cyan-600 bg-clip-text text-transparent">
                  E-Santé Admin
                </CardTitle>
                <CardDescription className="text-base font-normal">
                  Secure access to your healthcare administration platform
                </CardDescription>
              </div>
            </div>

            {/* Security Badge */}
            <div className="flex items-center justify-center gap-2 px-4 py-2 bg-green-50 dark:bg-green-950 border border-green-200 dark:border-green-900 rounded-full">
              <Shield className="w-4 h-4 text-green-600 dark:text-green-400" />
              <span className="text-xs font-semibold text-green-700 dark:text-green-300">
                Secure & Encrypted
              </span>
            </div>
          </CardHeader>

          {/* Form Section */}
          <form onSubmit={handleSubmit(onSubmit)}>
            <CardContent className="space-y-6">
              {/* Email Field */}
              <div className="space-y-2">
                <Label htmlFor="email" className="text-sm font-semibold flex items-center gap-2">
                  <Mail className="w-4 h-4 text-blue-600" />
                  Email Address
                </Label>
                <div className="relative">
                  <Input
                    id="email"
                    type="email"
                    placeholder="admin@esante.tn"
                    {...register('email')}
                    disabled={isLoading}
                    className="h-12 pl-11 text-base transition-all duration-300 focus:ring-2 focus:ring-blue-500/20"
                  />
                  <Mail className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-muted-400 transition-colors" />
                </div>
                {errors.email && (
                  <p className="text-sm text-red-600 dark:text-red-400 font-medium flex items-center gap-1">
                    <Lock className="w-3 h-3" />
                    {errors.email.message}
                  </p>
                )}
              </div>

              {/* Password Field */}
              <div className="space-y-2">
                <Label htmlFor="password" className="text-sm font-semibold flex items-center gap-2">
                  <Lock className="w-4 h-4 text-blue-600" />
                  Password
                </Label>
                <div className="relative">
                  <Input
                    id="password"
                    type="password"
                    placeholder="••••••••"
                    {...register('password')}
                    disabled={isLoading}
                    className="h-12 pl-11 text-base transition-all duration-300 focus:ring-2 focus:ring-blue-500/20"
                  />
                  <Lock className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-muted-400 transition-colors" />
                </div>
                {errors.password && (
                  <p className="text-sm text-red-600 dark:text-red-400 font-medium flex items-center gap-1">
                    <Lock className="w-3 h-3" />
                    {errors.password.message}
                  </p>
                )}
              </div>
            </CardContent>

            <CardFooter className="pt-2">
              {/* Submit Button */}
              <Button
                type="submit"
                className="w-full h-12 text-base font-semibold bg-gradient-to-r from-blue-600 to-blue-700 hover:from-blue-700 hover:to-blue-800 shadow-lg shadow-blue-500/30 transition-all duration-300 hover:shadow-xl hover:shadow-blue-500/40 hover:scale-[1.02]"
                disabled={isLoading}
              >
                {isLoading ? (
                  <>
                    <Loader2 className="mr-2 h-5 w-5 animate-spin" />
                    <span>Authenticating...</span>
                  </>
                ) : (
                  <>
                    <span>Sign In to Dashboard</span>
                    <ArrowRight className="ml-2 h-5 w-5 group-hover:translate-x-1 transition-transform" />
                  </>
                )}
              </Button>
            </CardFooter>
          </form>

          {/* Footer Section */}
          <div className="mt-4 pt-4 border-t border-gray-100 dark:border-gray-800">
            <div className="flex items-center justify-center gap-2 text-xs text-muted-foreground">
              <Shield className="w-3 h-3" />
              <span>Protected by enterprise-grade security</span>
            </div>
          </div>
        </Card>

        {/* Bottom Text */}
        <div className="mt-6 text-center space-y-2">
          <p className="text-sm text-muted-foreground">
            © 2024 E-Santé. All rights reserved.
          </p>
          <div className="flex items-center justify-center gap-2 text-xs text-muted-foreground">
            <span className="flex items-center gap-1">
              <CheckCircle2 className="w-3 h-3 text-green-600" />
              HIPAA Compliant
            </span>
            <span>•</span>
            <span className="flex items-center gap-1">
              <CheckCircle2 className="w-3 h-3 text-green-600" />
              GDPR Ready
            </span>
          </div>
        </div>
      </div>
    </div>
  );
}
