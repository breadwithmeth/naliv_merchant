import { create } from 'zustand';
import { AUTH_TOKEN_KEY, clearAuthToken, setAuthToken } from '../api/client';

type AuthState = {
  token: string | null;
  isAuthenticated: boolean;
  login: (token: string) => void;
  logout: () => void;
};

export const useAuthStore = create<AuthState>((set) => {
  const token = localStorage.getItem(AUTH_TOKEN_KEY);

  return {
    token,
    isAuthenticated: Boolean(token),
    login: (nextToken) => {
      setAuthToken(nextToken);
      set({ token: nextToken, isAuthenticated: true });
    },
    logout: () => {
      clearAuthToken();
      set({ token: null, isAuthenticated: false });
    },
  };
});
