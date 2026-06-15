import { useQuery } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";

export type ChatPermissions = {
  isAuthenticated: boolean;
  isSuperAdmin: boolean;
  isAdmin: boolean;
  isModerator: boolean;
  isStaff: boolean;
  canReply: boolean;
  canAssign: boolean;
  canDelete: boolean;
  canManageSettings: boolean;
  userId: string | null;
};

const EMPTY: ChatPermissions = {
  isAuthenticated: false,
  isSuperAdmin: false,
  isAdmin: false,
  isModerator: false,
  isStaff: false,
  canReply: false,
  canAssign: false,
  canDelete: false,
  canManageSettings: false,
  userId: null,
};

export function useChatPermissions(): ChatPermissions {
  const q = useQuery({
    queryKey: ["chat", "permissions"],
    staleTime: 60_000,
    queryFn: async (): Promise<ChatPermissions> => {
      const { data: u } = await supabase.auth.getUser();
      if (!u.user) return EMPTY;
      const userId = u.user.id;
      const { data: roles } = await supabase
        .from("user_roles")
        .select("role")
        .eq("user_id", userId);
      const set = new Set((roles ?? []).map((r) => r.role as string));
      const isSuperAdmin = set.has("super_admin");
      const isAdmin = isSuperAdmin || set.has("admin");
      const isModerator = set.has("moderator");
      const isStaff = isAdmin || isModerator;
      return {
        isAuthenticated: true,
        isSuperAdmin,
        isAdmin,
        isModerator,
        isStaff,
        canReply: isStaff,
        canAssign: isSuperAdmin,
        canDelete: isSuperAdmin,
        canManageSettings: isAdmin,
        userId,
      };
    },
  });
  return q.data ?? EMPTY;
}
