import { createFileRoute, Link } from "@tanstack/react-router";
import { useMemo, useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { useServerFn } from "@tanstack/react-start";
import {
  adminListSystemErrors,
  adminSystemHealthSummary,
  adminResolveSystemError,
  type SystemErrorRow,
} from "@/lib/admin-system-health.functions";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
} from "@/components/ui/dialog";
import {
  Activity,
  AlertTriangle,
  CheckCircle2,
  Download,
  RefreshCw,
  ShieldAlert,
} from "lucide-react";
import { toast } from "sonner";

export const Route = createFileRoute("/admin/system-health")({
  component: SystemHealthPage,
  head: () => ({ meta: [{ title: "System Health · CA Aspire BD Admin" }] }),
});

const SEVERITY_STYLES: Record<SystemErrorRow["severity"], string> = {
  critical: "bg-rose-500/20 text-rose-300 border-rose-500/30",
  high: "bg-orange-500/20 text-orange-300 border-orange-500/30",
  medium: "bg-amber-500/20 text-amber-300 border-amber-500/30",
  low: "bg-sky-500/20 text-sky-300 border-sky-500/30",
};

function toCsv(rows: SystemErrorRow[]): string {
  const cols = [
    "id",
    "severity",
    "source",
    "message",
    "route",
    "occurrence_count",
    "last_seen_at",
    "resolved",
  ] as const;
  const esc = (v: unknown) => {
    const s = v === null || v === undefined ? "" : String(v);
    return /[",\n\r]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
  };
  return [
    cols.join(","),
    ...rows.map((r) =>
      cols.map((c) => esc((r as unknown as Record<string, unknown>)[c])).join(","),
    ),
  ].join("\n");
}

function SystemHealthPage() {
  const qc = useQueryClient();
  const list = useServerFn(adminListSystemErrors);
  const summary = useServerFn(adminSystemHealthSummary);
  const resolve = useServerFn(adminResolveSystemError);

  const [page, setPage] = useState(0);
  const [pageSize] = useState(50);
  const [severity, setSeverity] = useState<string>("");
  const [source, setSource] = useState<string>("");
  const [resolved, setResolved] = useState<string>("open");
  const [q, setQ] = useState("");
  const [selected, setSelected] = useState<SystemErrorRow | null>(null);

  const filters = useMemo(
    () => ({
      page,
      pageSize,
      severity: (severity || undefined) as SystemErrorRow["severity"] | undefined,
      source: (source || undefined) as SystemErrorRow["source"] | undefined,
      resolved: resolved === "open" ? false : resolved === "resolved" ? true : undefined,
      q: q.trim() || undefined,
    }),
    [page, pageSize, severity, source, resolved, q],
  );

  const summaryQ = useQuery({ queryKey: ["sys-health-summary"], queryFn: () => summary() });
  const listQ = useQuery({
    queryKey: ["sys-health-list", filters],
    queryFn: () => list({ data: filters }),
  });

  const resolveM = useMutation({
    mutationFn: (vars: { id: string; resolved: boolean }) => resolve({ data: vars }),
    onSuccess: () => {
      toast.success("Updated");
      qc.invalidateQueries({ queryKey: ["sys-health-list"] });
      qc.invalidateQueries({ queryKey: ["sys-health-summary"] });
      setSelected(null);
    },
    onError: (e: Error) => toast.error(e.message),
  });

  const exportCsv = () => {
    if (!listQ.data?.rows.length) return;
    const blob = new Blob([toCsv(listQ.data.rows)], { type: "text/csv" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `system-errors-${new Date().toISOString().slice(0, 10)}.csv`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  };

  const s = summaryQ.data;
  const StatusIcon =
    s?.status === "healthy" ? CheckCircle2 : s?.status === "degraded" ? AlertTriangle : ShieldAlert;

  return (
    <div className="container mx-auto max-w-7xl space-y-6 px-4 py-6">
      <header className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <p className="text-xs text-muted-foreground">
            <Link to="/admin" className="hover:underline">
              Admin
            </Link>{" "}
            / System Health
          </p>
          <h1 className="font-display text-2xl font-bold">System Health & Error Logs</h1>
        </div>
        <div className="flex gap-2">
          <Button
            variant="outline"
            size="sm"
            onClick={() => {
              listQ.refetch();
              summaryQ.refetch();
            }}
          >
            <RefreshCw className="mr-2 h-4 w-4" /> Refresh
          </Button>
          <Button
            variant="outline"
            size="sm"
            onClick={exportCsv}
            disabled={!listQ.data?.rows.length}
          >
            <Download className="mr-2 h-4 w-4" /> Export CSV
          </Button>
        </div>
      </header>

      <section className="grid grid-cols-1 gap-4 md:grid-cols-3">
        <div className="glass-card rounded-2xl p-5">
          <p className="text-xs uppercase tracking-wider text-muted-foreground">Status</p>
          {summaryQ.isLoading ? (
            <Skeleton className="mt-2 h-7 w-24" />
          ) : (
            <div className="mt-2 flex items-center gap-2">
              <StatusIcon
                className={`h-5 w-5 ${s?.status === "healthy" ? "text-emerald-400" : s?.status === "degraded" ? "text-rose-400" : "text-amber-400"}`}
              />
              <span className="font-display text-xl font-bold capitalize">{s?.status ?? "—"}</span>
            </div>
          )}
        </div>
        <div className="glass-card rounded-2xl p-5">
          <p className="text-xs uppercase tracking-wider text-muted-foreground">Open errors</p>
          {summaryQ.isLoading ? (
            <Skeleton className="mt-2 h-7 w-16" />
          ) : (
            <p className="mt-2 font-display text-2xl font-bold">{s?.openErrors ?? 0}</p>
          )}
        </div>
        <div className="glass-card rounded-2xl p-5">
          <p className="text-xs uppercase tracking-wider text-muted-foreground">Critical (24h)</p>
          {summaryQ.isLoading ? (
            <Skeleton className="mt-2 h-7 w-16" />
          ) : (
            <p className="mt-2 font-display text-2xl font-bold text-rose-400">
              {s?.critical24h ?? 0}
            </p>
          )}
        </div>
      </section>

      <section className="glass-card rounded-2xl p-4">
        <div className="flex flex-wrap items-center gap-2">
          <Input
            value={q}
            onChange={(e) => {
              setPage(0);
              setQ(e.target.value);
            }}
            placeholder="Search message…"
            className="h-9 w-full max-w-xs"
          />
          <Select
            value={severity}
            onValueChange={(v) => {
              setPage(0);
              setSeverity(v === "all" ? "" : v);
            }}
          >
            <SelectTrigger className="h-9 w-40">
              <SelectValue placeholder="Severity" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">All severities</SelectItem>
              <SelectItem value="critical">Critical</SelectItem>
              <SelectItem value="high">High</SelectItem>
              <SelectItem value="medium">Medium</SelectItem>
              <SelectItem value="low">Low</SelectItem>
            </SelectContent>
          </Select>
          <Select
            value={source}
            onValueChange={(v) => {
              setPage(0);
              setSource(v === "all" ? "" : v);
            }}
          >
            <SelectTrigger className="h-9 w-40">
              <SelectValue placeholder="Source" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">All sources</SelectItem>
              <SelectItem value="frontend">Frontend</SelectItem>
              <SelectItem value="backend">Backend</SelectItem>
              <SelectItem value="db">Database</SelectItem>
              <SelectItem value="network">Network</SelectItem>
              <SelectItem value="unknown">Unknown</SelectItem>
            </SelectContent>
          </Select>
          <Select
            value={resolved}
            onValueChange={(v) => {
              setPage(0);
              setResolved(v);
            }}
          >
            <SelectTrigger className="h-9 w-36">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="open">Open</SelectItem>
              <SelectItem value="resolved">Resolved</SelectItem>
              <SelectItem value="all">All</SelectItem>
            </SelectContent>
          </Select>
        </div>

        <div className="mt-4 overflow-x-auto">
          <table className="w-full text-sm">
            <thead className="text-left text-xs uppercase text-muted-foreground">
              <tr>
                <th className="px-3 py-2">Sev</th>
                <th className="px-3 py-2">Source</th>
                <th className="px-3 py-2">Message</th>
                <th className="px-3 py-2">Route</th>
                <th className="px-3 py-2 text-right">Count</th>
                <th className="px-3 py-2">Last seen</th>
                <th className="px-3 py-2" />
              </tr>
            </thead>
            <tbody>
              {listQ.isLoading ? (
                Array.from({ length: 6 }).map((_, i) => (
                  <tr key={i}>
                    <td colSpan={7} className="px-3 py-2">
                      <Skeleton className="h-6 w-full" />
                    </td>
                  </tr>
                ))
              ) : listQ.data?.rows.length === 0 ? (
                <tr>
                  <td colSpan={7} className="px-3 py-10 text-center text-muted-foreground">
                    <Activity className="mx-auto mb-2 h-6 w-6 opacity-50" />
                    No errors match these filters. The system is quiet.
                  </td>
                </tr>
              ) : (
                listQ.data?.rows.map((r) => (
                  <tr
                    key={r.id}
                    className="cursor-pointer border-t border-border/40 hover:bg-accent/30"
                    onClick={() => setSelected(r)}
                  >
                    <td className="px-3 py-2">
                      <Badge variant="outline" className={SEVERITY_STYLES[r.severity]}>
                        {r.severity}
                      </Badge>
                    </td>
                    <td className="px-3 py-2 capitalize text-muted-foreground">{r.source}</td>
                    <td className="max-w-xl truncate px-3 py-2">{r.message}</td>
                    <td className="px-3 py-2 text-muted-foreground">{r.route ?? "—"}</td>
                    <td className="px-3 py-2 text-right font-mono">{r.occurrence_count}</td>
                    <td className="px-3 py-2 text-muted-foreground">
                      {new Date(r.last_seen_at).toLocaleString()}
                    </td>
                    <td className="px-3 py-2 text-right">
                      {r.resolved ? (
                        <Badge
                          variant="outline"
                          className="bg-emerald-500/20 text-emerald-300 border-emerald-500/30"
                        >
                          Resolved
                        </Badge>
                      ) : null}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        <div className="mt-4 flex items-center justify-between text-xs text-muted-foreground">
          <span>{listQ.data?.total ?? 0} total</span>
          <div className="flex gap-2">
            <Button
              size="sm"
              variant="outline"
              disabled={page === 0}
              onClick={() => setPage((p) => Math.max(0, p - 1))}
            >
              Prev
            </Button>
            <Button
              size="sm"
              variant="outline"
              disabled={!listQ.data || (page + 1) * pageSize >= (listQ.data.total ?? 0)}
              onClick={() => setPage((p) => p + 1)}
            >
              Next
            </Button>
          </div>
        </div>
      </section>

      <Dialog open={!!selected} onOpenChange={(o) => !o && setSelected(null)}>
        <DialogContent className="max-w-3xl">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              {selected ? (
                <Badge variant="outline" className={SEVERITY_STYLES[selected.severity]}>
                  {selected.severity}
                </Badge>
              ) : null}
              <span className="truncate">{selected?.message}</span>
            </DialogTitle>
            <DialogDescription className="text-xs">
              {selected?.source} · {selected?.route ?? "no route"} · seen{" "}
              {selected?.occurrence_count}× · last{" "}
              {selected ? new Date(selected.last_seen_at).toLocaleString() : ""}
            </DialogDescription>
          </DialogHeader>
          {selected ? (
            <div className="space-y-4 text-sm">
              {selected.stack ? (
                <div>
                  <p className="mb-1 text-xs font-semibold uppercase text-muted-foreground">
                    Stack
                  </p>
                  <pre className="max-h-64 overflow-auto rounded-lg bg-muted/40 p-3 text-xs">
                    {selected.stack}
                  </pre>
                </div>
              ) : null}
              {selected.payload ? (
                <div>
                  <p className="mb-1 text-xs font-semibold uppercase text-muted-foreground">
                    Payload
                  </p>
                  <pre className="max-h-48 overflow-auto rounded-lg bg-muted/40 p-3 text-xs">
                    {JSON.stringify(selected.payload, null, 2)}
                  </pre>
                </div>
              ) : null}
              <div className="flex justify-end gap-2">
                <Button
                  variant="outline"
                  onClick={() => resolveM.mutate({ id: selected.id, resolved: !selected.resolved })}
                  disabled={resolveM.isPending}
                >
                  {selected.resolved ? "Reopen" : "Mark resolved"}
                </Button>
              </div>
            </div>
          ) : null}
        </DialogContent>
      </Dialog>
    </div>
  );
}
