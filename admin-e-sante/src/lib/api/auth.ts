import { api, type AuthResponse, type LoginRequest, type User } from './client';
import { setToken, setRefreshToken } from './client';

// Auth Service
export const authService = {
  async login(credentials: LoginRequest): Promise<AuthResponse> {
    const response = await api.post<AuthResponse>('/auth/login', credentials);
    setToken(response.accessToken);
    setRefreshToken(response.refreshToken);
    return response;
  },

  async logout(): Promise<void> {
    try {
      await api.post('/auth/logout');
    } catch (error) {
      console.error('Logout error:', error);
    } finally {
      setToken('');
      setRefreshToken('');
    }
  },

  async getCurrentUser(): Promise<User> {
    const response = await api.get<{ user: User }>('/auth/me');
    return response.user;
  },

  async refreshToken(): Promise<AuthResponse> {
    const response = await api.post<AuthResponse>('/auth/refresh');
    setToken(response.accessToken);
    setRefreshToken(response.refreshToken);
    return response;
  },
};
