'use client';

import { useEffect, useState, createContext, useContext } from 'react';
import { io, Socket } from 'socket.io-client';
import { getToken } from '@/lib/api/client';

interface SocketContextType {
  notificationSocket: Socket | null;
  userSocket: Socket | null;
  appointmentSocket: Socket | null;
  isConnected: boolean;
}

const SocketContext = createContext<SocketContextType>({
  notificationSocket: null,
  userSocket: null,
  appointmentSocket: null,
  isConnected: false,
});

export function useSocket() {
  return useContext(SocketContext);
}

export function SocketProvider({ children }: { children: React.ReactNode }) {
  const [notificationSocket, setNotificationSocket] = useState<Socket | null>(null);
  const [userSocket, setUserSocket] = useState<Socket | null>(null);
  const [appointmentSocket, setAppointmentSocket] = useState<Socket | null>(null);
  const [isConnected, setIsConnected] = useState(false);

  useEffect(() => {
    const token = getToken();
    if (!token) return;

    let anyConnected = false;

    // 1. Notification Socket (Port 3007 - Direct)
    const notifSocket = io('http://localhost:3007', {
      auth: { token },
      transports: ['websocket', 'polling'],
    });

    // 2. User Socket (via API Gateway on port 3000)
    const usrSocket = io('http://localhost:3000', {
      path: '/user-socket',
      auth: { token },
      transports: ['websocket', 'polling'],
    });

    // 3. Appointment Socket (via API Gateway on port 3000)
    const rdvSocket = io('http://localhost:3000', {
      path: '/rdv-socket',
      auth: { token },
      transports: ['websocket', 'polling'],
    });

    const handleConnect = () => {
      console.log('✅ Socket connected');
      anyConnected = true;
      setIsConnected(true);
    };

    const handleDisconnect = () => {
      console.log('❌ Socket disconnected');
      anyConnected = false;
      setIsConnected(false);
    };

    const handleError = (error: any) => {
      console.error('Socket error:', error);
    };

    // Setup connection handlers for all sockets
    [notifSocket, usrSocket, rdvSocket].forEach((socket) => {
      socket.on('connect', handleConnect);
      socket.on('disconnect', handleDisconnect);
      socket.on('connect_error', handleError);
    });

    setNotificationSocket(notifSocket);
    setUserSocket(usrSocket);
    setAppointmentSocket(rdvSocket);

    return () => {
      [notifSocket, usrSocket, rdvSocket].forEach((socket) => {
        socket.disconnect();
        socket.off('connect', handleConnect);
        socket.off('disconnect', handleDisconnect);
        socket.off('connect_error', handleError);
      });
    };
  }, []);

  return (
    <SocketContext.Provider
      value={{
        notificationSocket,
        userSocket,
        appointmentSocket,
        isConnected,
      }}
    >
      {children}
    </SocketContext.Provider>
  );
}
