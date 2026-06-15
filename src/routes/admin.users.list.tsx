import { createFileRoute, Link, useNavigate } from "@tanstack/react-router";
import { zodValidator, fallback } from "@tanstack/zod-adapter";
import { z } from "zod";
import { useMemo, useState } from "react";
import { keepPreviousData, useQuery } from "@tanstack/react-query";
import { useServerFn } from "@tanstack/react-start";
import {
  ArrowLeft,
  Search,
  Download,
  Loader2,
  BadgeCheck,
  Crown,
  ShieldCheck,
  Activity,
  Filter as FilterIcon,
} from "lucide-react";
import { adminListUsers } from "@/lib/admin-users.functions";
import { getRoleDisplayName } from "@/lib/role-display";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";

const statusEnum = z.enum(["active", "suspended", "pending", "deleted"]);
const roleEnum = z.enum(["admin", "moderator", "student"]);
const dateEnum = z.enum(["24h", "7d", "30d", "lifetime"]);
const sortEnum = z.enum(["recent", "name", "logins", "usage", "lastLogin"]);

const searchSchema = z.object({
  status: fallback(statusEnum.optional(), undefined),
  role: fallback(roleEnum.optional(), undefined),
  verified: fallback(z.boolean().optional(), undefined),
  dateRange: fallback(dateEnum.optional(), undefined),
  q: fallback(z.string().max(200), "").default(""),
  sort: fallback(sortEnum, "recent").default("recent"),
  page: fallback(z.number().int().min(1), 1).default(1),
  pageSize: fallback(z.number().int().min(10).max(100), 25).default(25),
  title: fallback(z.string().max(80), "").default(""),
});

export const Route = createFileRoute("/admin/users/list")({
  validateSearch: zodValidator(searchSchema),
  component: AdminUsersListPage,
  head: () => ({
    meta: [
      { title: "User Drilldown · CA Aspire BD Admin" },
      {
        name: "description",
        content: "Filtered drilldown of users across status, role, verification and activity.",
      },
    ],
  }),
});

type Row = {
  id: string;
  display_name: string;
  level: string;
  status: string;
  email: string | null;
  email_verified: boolean;
  roles: string[];
  last_login_at: string | null;
  total_login_count: number | null;
  total_usage_seconds: number | null;
  created_at: string;
};

function AdminUsersListPage() {
  const search = Route.useSearch();
  const navigate = useNavigate({ from: "/admin/users/list" });
  const [q, setQ] = useState(search.q);

  const listFn = useServerFn(adminListUsers);
  const queryKey = ["admin-users-drilldown", search] as const;
  const { data, isFetching, error } = useQuery({
    queryKey,
    queryFn: () =>
      listFn({
        data: {
          search: search.q || undefined,
          status: search.status,
          role: search.role,
          verified: search.verified,
          dateRange: search.dateRange,
          page: search.page,
          pageSize: search.pageSize,
        },
      }),
    placeholderData: keepPreviousData,
  });

  const rows: Row[] = (data?.rows ?? []) as Row[];
  const sorted = useMemo(() => {
    const arr = [...rows];
    switch (search.sort) {
      case "name":
        arr.sort((a, b) => a.display_name.localeCompare(b.display_name));
        break;
      case "logins":
        arr.sort((a, b) => (b.total_login_count ?? 0) - (a.total_login_count ?? 0));
        break;
      case "usage":
        arr.sort((a, b) => (b.total_usage_seconds ?? 0) - (a.total_usage_seconds ?? 0));
        break;
      case "lastLogin":
        arr.sort(
          (a, b) =>
            new Date(b.last_login_at ?? 0).getTime() - new Date(a.last_login_at ?? 0).getTime(),
        );
        break;
      default:
        arr.sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime());
    }
    return arr;
  }, [rows, search.sort]);

  const total = data?.count ?? 0;
  const totalPages = Math.max(1, Math.ceil(total / search.pageSize));

  function update(patch: Partial<typeof search>) {
    navigate({ search: (prev) => ({ ...prev, ...patch, page: patch.page ?? 1 }) });
  }

  function exportCsv() {
    const header = [
      "id",
      "name",
      "email",
      "level",
      "status",
      "verified",
      "roles",
      "logins",
      "usage_seconds",
      "last_login_at",
      "created_at",
    ];
    const lines = [header.join(",")].concat(
      sorted.map((r) =>
        [
          r.id,
          csv(r.display_name),
          csv(r.email ?? ""),
          csv(r.level),
          csv(r.status),
          r.email_verified ? "yes" : "no",
          csv((r.roles ?? []).join("|")),
          r.total_login_count ?? 0,
          r.total_usage_seconds ?? 0,
          r.last_login_at ?? "",
          r.created_at,
        ].join(","),
      ),
    );
    const blob = new Blob([lines.join("\n")], { type: "text/csv" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `users-${Date.now()}.csv`;
    a.click();
    URL.revokeObjectURL(url);
  }

  const heading = search.title || buildTitle(search);

  return (
    <div className="space-y-5 p-4 lg:p-6">
      <header className="glass shadow-card-soft rounded-2xl p-5">
        <div className="flex flex-wrap items-end justify-between gap-3">
          <div className="space-y-2">
            <Link
              to="/admin/users"
              className="inline-flex items-center gap-1 text-xs text-muted-foreground hover:text-foreground"
            >
              <ArrowLeft className="h-3 w-3" /> Back to User Management
            </Link>
            <h1 className="font-display text-2xl font-bold tracking-tight md:text-3xl">
              {heading}
            </h1>
            <p className="text-xs text-muted-foreground">
              {isFetching
                ? "Loading…"
                : `${total.toLocaleString()} matching ${total === 1 ? "user" : "users"}`}
            </p>
          </div>
          <div className="flex flex-wrap items-center gap-2">
            <Badge variant="outline" className="rounded-xl">
              <FilterIcon className="mr-1 h-3 w-3" />
              {summarizeFilters(search) || "All users"}
            </Badge>
            <Button size="sm" variant="outline" className="rounded-xl" onClick={exportCsv}>
              <Download className="mr-1 h-4 w-4" /> Export CSV
            </Button>
          </div>
        </div>
      </header>

      <section className="glass shadow-card-soft grid grid-cols-1 gap-3 rounded-2xl p-4 md:grid-cols-5">
        <div className="relative md:col-span-2">
          <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
          <Input
            value={q}
            onChange={(e) => setQ(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === "Enter") update({ q });
            }}
            onBlur={() => {
              if (q !== search.q) update({ q });
            }}
            placeholder="Search name, email, or user id…"
            className="rounded-xl pl-9"
          />
        </div>
        <Select
          value={search.status ?? "all"}
          onValueChange={(v) =>
            update({ status: v === "all" ? undefined : (v as z.infer<typeof statusEnum>) })
          }
        >
          <SelectTrigger className="rounded-xl">
            <SelectValue placeholder="Status" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All status</SelectItem>
            <SelectItem value="active">Active</SelectItem>
            <SelectItem value="pending">Pending</SelectItem>
            <SelectItem value="suspended">Suspended</SelectItem>
            <SelectItem value="deleted">Deleted</SelectItem>
          </SelectContent>
        </Select>
        <Select
          value={search.role ?? "all"}
          onValueChange={(v) =>
            update({ role: v === "all" ? undefined : (v as z.infer<typeof roleEnum>) })
          }
        >
          <SelectTrigger className="rounded-xl">
            <SelectValue placeholder="Role" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All roles</SelectItem>
            <SelectItem value="admin">Admin</SelectItem>
            <SelectItem value="moderator">Moderator</SelectItem>
            <SelectItem value="student">Student</SelectItem>
          </SelectContent>
        </Select>
        <Select
          value={search.sort}
          onValueChange={(v) => update({ sort: v as z.infer<typeof sortEnum> })}
        >
          <SelectTrigger className="rounded-xl">
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="recent">Newest first</SelectItem>
            <SelectItem value="lastLogin">Latest login</SelectItem>
            <SelectItem value="logins">Most logins</SelectItem>
            <SelectItem value="usage">Most usage</SelectItem>
            <SelectItem value="name">Name (A–Z)</SelectItem>
          </SelectContent>
        </Select>
      </section>

      <section className="glass shadow-card-soft overflow-hidden rounded-2xl">
        <div className="overflow-x-auto">
          <table className="w-full text-xs">
            <thead className="bg-muted/30 text-[11px] uppercase tracking-wide text-muted-foreground">
              <tr>
                <th className="px-3 py-3 text-left font-medium">User</th>
                <th className="px-3 py-3 text-left font-medium">Email</th>
                <th className="px-3 py-3 text-left font-medium">Level</th>
                <th className="px-3 py-3 text-left font-medium">Status</th>
                <th className="px-3 py-3 text-left font-medium">Roles</th>
                <th className="px-3 py-3 text-left font-medium">Logins</th>
                <th className="px-3 py-3 text-left font-medium">Last login</th>
              </tr>
            </thead>
            <tbody>
              {isFetching && sorted.length === 0 && (
                <tr>
                  <td colSpan={7} className="px-3 py-10 text-center text-muted-foreground">
                    <Loader2 className="mr-1 inline h-4 w-4 animate-spin" /> Loading users…
                  </td>
                </tr>
              )}
              {!isFetching && sorted.length === 0 && (
                <tr>
                  <td colSpan={7} className="px-3 py-10 text-center text-muted-foreground">
                    No users match these filters.
                  </td>
                </tr>
              )}
              {sorted.map((u) => (
                <tr key={u.id} className="border-t border-border/40 hover:bg-muted/20">
                  <td className="px-3 py-3">
                    <div className="font-medium text-foreground">{u.display_name}</div>
                    <div className="text-[10px] text-muted-foreground">{u.id.slice(0, 8)}…</div>
                  </td>
                  <td className="px-3 py-3 text-muted-foreground">
                    <span className="inline-flex items-center gap-1">
                      {u.email ?? "—"}
                      {u.email_verified && <BadgeCheck className="h-3 w-3 text-emerald-400" />}
                    </span>
                  </td>
                  <td className="px-3 py-3 text-muted-foreground">{u.level}</td>
                  <td className="px-3 py-3">
                    <StatusBadge status={u.status} />
                  </td>
                  <td className="px-3 py-3">
                    <div className="flex flex-wrap gap-1">
                      {(u.roles ?? []).map((r) => (
                        <RoleBadge key={r} role={r} />
                      ))}
                      {(!u.roles || u.roles.length === 0) && (
                        <span className="text-muted-foreground">—</span>
                      )}
                    </div>
                  </td>
                  <td className="px-3 py-3 text-muted-foreground">
                    {(u.total_login_count ?? 0).toLocaleString()}
                  </td>
                  <td className="px-3 py-3 text-muted-foreground">
                    {fmtDateTime(u.last_login_at)}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        <div className="flex items-center justify-between gap-2 border-t border-border/40 px-3 py-2 text-xs text-muted-foreground">
          <div>
            Page {search.page} of {totalPages}
          </div>
          <div className="flex items-center gap-2">
            <Button
              size="sm"
              variant="outline"
              className="rounded-lg"
              disabled={search.page <= 1}
              onClick={() => update({ page: search.page - 1 })}
            >
              Prev
            </Button>
            <Button
              size="sm"
              variant="outline"
              className="rounded-lg"
              disabled={search.page >= totalPages}
              onClick={() => update({ page: search.page + 1 })}
            >
              Next
            </Button>
          </div>
        </div>
      </section>
      {error && <p className="text-xs text-destructive">{(error as Error).message}</p>}
    </div>
  );
}

function StatusBadge({ status }: { status: string }) {
  const map: Record<string, string> = {
    active: "bg-emerald-500/15 text-emerald-400",
    pending: "bg-amber-500/15 text-amber-400",
    suspended: "bg-rose-500/15 text-rose-400",
    deleted: "bg-muted text-muted-foreground",
  };
  return (
    <span
      className={`rounded-md px-2 py-0.5 text-[10px] font-medium ${map[status] ?? "bg-muted text-muted-foreground"}`}
    >
      {status}
    </span>
  );
}

function RoleBadge({ role }: { role: string }) {
  const Icon = role === "admin" ? Crown : role === "moderator" ? ShieldCheck : Activity;
  return (
    <span className="inline-flex items-center gap-1 rounded-md bg-violet-500/10 px-1.5 py-0.5 text-[10px] font-medium text-violet-300">
      <Icon className="h-3 w-3" /> {getRoleDisplayName(role)}
    </span>
  );
}

function fmtDateTime(iso: string | null) {
  if (!iso) return "Never";
  const d = new Date(iso);
  return d.toLocaleString(undefined, { dateStyle: "medium", timeStyle: "short" });
}

function csv(v: string) {
  if (/[",\n]/.test(v)) return `"${v.replace(/"/g, '""')}"`;
  return v;
}

function buildTitle(s: z.infer<typeof searchSchema>) {
  if (s.verified === true) return "Verified users";
  if (s.verified === false) return "Unverified users";
  if (s.role === "admin") return "Administrators";
  if (s.role === "moderator") return "Moderators";
  if (s.status === "active") return "Active users";
  if (s.status === "pending") return "Pending users";
  if (s.status === "suspended") return "Suspended users";
  if (s.status === "deleted") return "Deleted users";
  if (s.dateRange === "24h") return "Active in last 24 hours";
  if (s.dateRange === "7d") return "Active in last 7 days";
  if (s.dateRange === "30d") return "Active in last 30 days";
  return "All users";
}

function summarizeFilters(s: z.infer<typeof searchSchema>) {
  const parts: string[] = [];
  if (s.status) parts.push(`status: ${s.status}`);
  if (s.role) parts.push(`role: ${s.role}`);
  if (s.verified === true) parts.push("verified");
  if (s.verified === false) parts.push("unverified");
  if (s.dateRange) parts.push(`active: ${s.dateRange}`);
  if (s.q) parts.push(`search: "${s.q}"`);
  return parts.join(" · ");
}
