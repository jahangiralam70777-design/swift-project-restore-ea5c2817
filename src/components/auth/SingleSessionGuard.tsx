import { useEffect, useRef } from "react";
import { useNavigate } from "@tanstack/react-router";
import { toast } from "sonner";
import { useAppStore } from "@/stores/app-store";
import { signOut } from "@/lib/auth-client";
import {
  clearLocalSessionId,
  getLocalSessionId,
  installSingleSessionGuard,
} from "@/lib/single-session";

/**
 * Live single-session enforcement. Mounted once in the root tree.
 *
 * When a different device signs in for the same account (or the row is
 * deleted), this component signs the current device out and surfaces a
 * friendly explanation.
 */
export function SingleSessionGuard() {
  const user = useAppStore((s) => s.user);
  const navigate = useNavigate();
  const kickedRef = useRef(false);

  useEffect(() => {
    if (!user?.id) return;
    // If there's no local session id yet on this device (e.g. older login
    // pre-dating this feature), don't kick — wait until the next sign-in
    // claims one. The guard still installs so future row changes are caught
    // once a sid exists.
    if (!getLocalSessionId(user.id)) return;
    kickedRef.current = false;

    const handle = installSingleSessionGuard(user.id, async (reason) => {
      // Only react to an explicit takeover by another device. A "missing"
      // result (no DB row, transient read error, Realtime DELETE replay,
      // or row not yet visible right after login) must NOT log the user
      // out — that caused false logouts on navigation/refresh.
      if (reason !== "kicked") return;
      if (kickedRef.current) return;
      kickedRef.current = true;
      clearLocalSessionId(user.id);
      try {
        await signOut();
      } catch {
        /* noop */
      }
      toast.error("You have been logged in from another device.", { duration: 6000 });
      try {
        navigate({ to: "/login", replace: true });
      } catch {
        if (typeof window !== "undefined") window.location.replace("/login");
      }
    });

    return () => handle.stop();
  }, [user?.id, navigate]);

  return null;
}
