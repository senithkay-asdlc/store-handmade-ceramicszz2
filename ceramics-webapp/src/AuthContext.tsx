import { createContext, useCallback, useContext, useEffect, useState, type ReactNode } from "react";
import type { User } from "oidc-client-ts";
import { currentUser, getRoles, isStoreOwner, signIn as startSignIn, signOut as endSignOut } from "./auth";

type AuthState = {
  user: User | null;
  loading: boolean;
  isOwner: boolean;
  signIn: (returnTo?: string) => Promise<void>;
  signOut: () => Promise<void>;
  refresh: () => Promise<void>;
};

const AuthContext = createContext<AuthState | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [isOwner, setIsOwner] = useState(false);
  const [loading, setLoading] = useState(true);

  const refresh = useCallback(async () => {
    const u = await currentUser();
    setUser(u);
    if (u) {
      const roles = await getRoles();
      setIsOwner(isStoreOwner(roles));
    } else {
      setIsOwner(false);
    }
    setLoading(false);
  }, []);

  useEffect(() => {
    refresh();
  }, [refresh]);

  const value: AuthState = {
    user,
    loading,
    isOwner,
    signIn: startSignIn,
    signOut: endSignOut,
    refresh,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthState {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used within an AuthProvider");
  return ctx;
}
