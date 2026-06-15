import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useServerFn } from "@tanstack/react-start";
import { toast } from "sonner";
import {
  Loader2, Send, Megaphone, Pin, PinOff, EyeOff, Eye, Trash2, FileText, History,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { useChatPermissions } from "@/hooks/use-chat-permissions";
import {
  createBroadcast, listBroadcasts, setBroadcastVisibility, setBroadcastPinned,
  deleteBroadcast, listTemplates, createTemplate, deleteTemplate, archiveTemplate,
  type BroadcastPriority, type BroadcastTargetKind, type Broadcast, type BroadcastTemplate,
} from "@/lib/broadcasts.functions";

const PRIORITY_COLORS: Record<BroadcastPriority, string> = {
  normal: "bg-slate-500/15 text-slate-700 dark:text-slate-300",
  important: "bg-amber-500/20 text-amber-700 dark:text-amber-300",
  urgent: "bg-rose-500/20 text-rose-700 dark:text-rose-300",
};

const TARGETS: { value: BroadcastTargetKind; label: string }[] = [
  { value: "all_students", label: "All Students" },
  { value: "active_users", label: "Active Users (30d)" },
  { value: "new_users", label: "Newly Registered" },
  { value: "users", label: "Specific Users" },
];

const NEW_PRESETS = [
  { value: "today", label: "Today" },
  { value: "24h", label: "Last 24h" },
  { value: "3d", label: "Last 3 days" },
  { value: "7d", label: "Last 7 days" },
  { value: "15d", label: "Last 15 days" },
  { value: "30d", label: "Last 30 days" },
];

export function BroadcastManager() {
  const perms = useChatPermissions();
  const qc = useQueryClient();
  const createFn = useServerFn(createBroadcast);
  const listFn = useServerFn(listBroadcasts);
  const visFn = useServerFn(setBroadcastVisibility);
  const pinFn = useServerFn(setBroadcastPinned);
  const delFn = useServerFn(deleteBroadcast);
  const tplListFn = useServerFn(listTemplates);
  const tplCreateFn = useServerFn(createTemplate);
  const tplDelFn = useServerFn(deleteTemplate);
  const tplArchiveFn = useServerFn(archiveTemplate);

  const [tab, setTab] = useState<"compose" | "history" | "templates">("compose");
  const [subject, setSubject] = useState("");
  const [body, setBody] = useState("");
  const [priority, setPriority] = useState<BroadcastPriority>("normal");
  const [methods, setMethods] = useState<string[]>(["inbox"]);
  const [target, setTarget] = useState<BroadcastTargetKind>("all_students");
  const [newPreset, setNewPreset] = useState("7d");
  const [userIds, setUserIds] = useState("");
  const [tplName, setTplName] = useState("");

  const histQ = useQuery({
    queryKey: ["broadcasts", "history"],
    queryFn: () => listFn(),
    enabled: perms.isAdmin || perms.isSuperAdmin,
    refetchInterval: 15_000,
  });
  const tplQ = useQuery({
    queryKey: ["broadcasts", "templates"],
    queryFn: () => tplListFn(),
    enabled: perms.isAdmin || perms.isSuperAdmin,
  });

  const createMut = useMutation({
    mutationFn: async () => {
      const filter: Record<string, unknown> = {};
      if (target === "new_users") filter.preset = newPreset;
      if (target === "users") {
        filter.user_ids = userIds.split(/[,\s]+/).map((s) => s.trim()).filter(Boolean);
      }
      return createFn({
        data: {
          subject, body, priority, delivery_methods: methods as ("inbox" | "chat" | "popup")[],
          target_kind: target, target_filter: filter,
        },
      });
    },
    onSuccess: (r) => {
      toast.success(`Broadcast sent to ${r.recipient_count} user(s)`);
      setSubject(""); setBody("");
      qc.invalidateQueries({ queryKey: ["broadcasts"] });
      setTab("history");
    },
    onError: (e) => toast.error((e as Error).message),
  });

  const saveTplMut = useMutation({
    mutationFn: async () => tplCreateFn({
      data: {
        name: tplName || subject || "Untitled",
        subject, body, priority,
        delivery_methods: methods as ("inbox" | "chat" | "popup")[],
        target_kind: target, target_filter: {},
      },
    }),
    onSuccess: () => {
      toast.success("Template saved");
      setTplName("");
      qc.invalidateQueries({ queryKey: ["broadcasts", "templates"] });
    },
    onError: (e) => toast.error((e as Error).message),
  });

  if (!perms.isAdmin && !perms.isSuperAdmin) {
    return (
      <div className="rounded-2xl border border-border bg-card p-8 text-center text-sm text-muted-foreground">
        Broadcasts are restricted to admins and super admins.
      </div>
    );
  }

  const toggleMethod = (m: string) =>
    setMethods((cur) => (cur.includes(m) ? cur.filter((x) => x !== m) : [...cur, m]));

  const useTemplate = (t: BroadcastTemplate) => {
    setSubject(t.subject); setBody(t.body); setPriority(t.priority);
    setMethods(t.delivery_methods); if (t.target_kind) setTarget(t.target_kind);
    setTab("compose");
    toast.success(`Loaded template: ${t.name}`);
  };

  return (
    <div className="space-y-4">
      <div className="flex items-center gap-3">
        <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-primary/10 text-primary">
          <Megaphone className="h-5 w-5" />
        </div>
        <div>
          <h2 className="text-xl font-bold tracking-tight">Broadcast Messages</h2>
          <p className="text-xs text-muted-foreground">Send announcements to your users</p>
        </div>
      </div>

      <div className="flex gap-1 border-b border-border">
        {(["compose", "history", "templates"] as const).map((t) => (
          <button key={t} onClick={() => setTab(t)}
            className={`px-4 py-2 text-sm font-medium capitalize transition ${
              tab === t ? "border-b-2 border-primary text-foreground" : "text-muted-foreground hover:text-foreground"
            }`}>
            {t}
          </button>
        ))}
      </div>

      {tab === "compose" && (
        <div className="space-y-4 rounded-2xl border border-border bg-card p-5">
          <div className="flex items-center gap-2">
            <span className="rounded-full bg-primary px-3 py-1 text-xs font-bold text-primary-foreground">
              FROM ADMIN
            </span>
          </div>

          <div>
            <label className="mb-1 block text-xs font-semibold uppercase tracking-wider text-muted-foreground">Subject</label>
            <Input value={subject} onChange={(e) => setSubject(e.target.value)} placeholder="Welcome to CA Aspire BD" maxLength={200} />
          </div>
          <div>
            <label className="mb-1 block text-xs font-semibold uppercase tracking-wider text-muted-foreground">Message</label>
            <Textarea value={body} onChange={(e) => setBody(e.target.value)} placeholder="Write your message…" rows={6} maxLength={5000} />
          </div>

          <div className="grid gap-4 md:grid-cols-2">
            <div>
              <label className="mb-1 block text-xs font-semibold uppercase tracking-wider text-muted-foreground">Priority</label>
              <div className="flex gap-2">
                {(["normal", "important", "urgent"] as const).map((p) => (
                  <button key={p} onClick={() => setPriority(p)}
                    className={`rounded-full px-3 py-1.5 text-xs font-semibold capitalize transition ${
                      priority === p ? PRIORITY_COLORS[p] + " ring-2 ring-offset-1 ring-current" : "bg-muted text-foreground/70 hover:bg-muted/80"
                    }`}>
                    {p}
                  </button>
                ))}
              </div>
            </div>
            <div>
              <label className="mb-1 block text-xs font-semibold uppercase tracking-wider text-muted-foreground">Delivery Methods</label>
              <div className="flex flex-wrap gap-2">
                {["inbox", "chat", "popup"].map((m) => (
                  <label key={m} className={`flex cursor-pointer items-center gap-2 rounded-full border px-3 py-1.5 text-xs font-medium capitalize ${
                    methods.includes(m) ? "border-primary bg-primary/10 text-primary" : "border-border text-foreground/70"
                  }`}>
                    <input type="checkbox" className="sr-only" checked={methods.includes(m)} onChange={() => toggleMethod(m)} />
                    {m}
                  </label>
                ))}
              </div>
            </div>
          </div>

          <div>
            <label className="mb-1 block text-xs font-semibold uppercase tracking-wider text-muted-foreground">Target Audience</label>
            <div className="flex flex-wrap gap-2">
              {TARGETS.map((t) => (
                <button key={t.value} onClick={() => setTarget(t.value)}
                  className={`rounded-full px-3 py-1.5 text-xs font-medium transition ${
                    target === t.value ? "bg-primary text-primary-foreground" : "bg-muted text-foreground/70 hover:bg-muted/80"
                  }`}>
                  {t.label}
                </button>
              ))}
            </div>
            {target === "new_users" && (
              <div className="mt-3 flex flex-wrap gap-2">
                {NEW_PRESETS.map((p) => (
                  <button key={p.value} onClick={() => setNewPreset(p.value)}
                    className={`rounded-md border px-2.5 py-1 text-[11px] font-medium transition ${
                      newPreset === p.value ? "border-primary bg-primary/10 text-primary" : "border-border text-foreground/70"
                    }`}>
                    {p.label}
                  </button>
                ))}
              </div>
            )}
            {target === "users" && (
              <Textarea className="mt-3" rows={3} placeholder="user IDs separated by commas or whitespace"
                value={userIds} onChange={(e) => setUserIds(e.target.value)} />
            )}
          </div>

          <div className="flex flex-wrap items-center gap-2 border-t border-border pt-4">
            <Input className="max-w-[240px]" placeholder="Template name (optional)" value={tplName} onChange={(e) => setTplName(e.target.value)} />
            {perms.isSuperAdmin && (
              <Button variant="outline" onClick={() => saveTplMut.mutate()} disabled={!subject || !body || saveTplMut.isPending}>
                <FileText className="mr-1 h-4 w-4" /> Save as template
              </Button>
            )}
            <div className="flex-1" />
            <Button onClick={() => createMut.mutate()} disabled={!subject || !body || methods.length === 0 || createMut.isPending}
              className="bg-cta-gradient text-white shadow-glow">
              {createMut.isPending ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : <Send className="mr-2 h-4 w-4" />}
              Send Broadcast
            </Button>
          </div>
        </div>
      )}

      {tab === "history" && (
        <div className="space-y-2">
          {histQ.isLoading && <div className="flex justify-center py-8"><Loader2 className="h-5 w-5 animate-spin text-muted-foreground" /></div>}
          {!histQ.isLoading && (histQ.data ?? []).length === 0 && (
            <div className="rounded-xl border border-dashed border-border p-12 text-center text-sm text-muted-foreground">
              <History className="mx-auto mb-2 h-8 w-8 opacity-50" /> No broadcasts sent yet
            </div>
          )}
          {(histQ.data ?? []).map((b: Broadcast) => {
            const total = b.recipient_count || 1;
            const readPct = Math.round(((b.read_count ?? 0) / total) * 100);
            return (
              <div key={b.id} className="rounded-xl border border-border bg-card p-4">
                <div className="flex items-start justify-between gap-3">
                  <div className="min-w-0 flex-1">
                    <div className="flex flex-wrap items-center gap-2">
                      <h4 className="text-sm font-semibold text-foreground">{b.subject}</h4>
                      <span className={`rounded-full px-2 py-0.5 text-[10px] font-bold uppercase ${PRIORITY_COLORS[b.priority]}`}>{b.priority}</span>
                      {b.pinned && <Pin className="h-3 w-3 text-amber-500" />}
                      {!b.visible && <span className="rounded bg-muted px-1.5 py-0.5 text-[10px] text-muted-foreground">HIDDEN</span>}
                    </div>
                    <p className="mt-1 line-clamp-2 text-xs text-foreground/75">{b.body}</p>
                    <p className="mt-2 text-[11px] text-muted-foreground">
                      {b.sender_name ?? "Admin"} · {new Date(b.created_at).toLocaleString()} · {b.recipient_count} recipients · {b.read_count ?? 0} read ({readPct}%)
                    </p>
                  </div>
                  <div className="flex shrink-0 gap-1">
                    <Button size="sm" variant="ghost" onClick={() => pinFn({ data: { id: b.id, pinned: !b.pinned } }).then(() => qc.invalidateQueries({ queryKey: ["broadcasts"] }))}>
                      {b.pinned ? <PinOff className="h-3.5 w-3.5" /> : <Pin className="h-3.5 w-3.5" />}
                    </Button>
                    {perms.isSuperAdmin && (
                      <>
                        <Button size="sm" variant="ghost" onClick={() => visFn({ data: { id: b.id, visible: !b.visible } }).then(() => qc.invalidateQueries({ queryKey: ["broadcasts"] }))}>
                          {b.visible ? <EyeOff className="h-3.5 w-3.5" /> : <Eye className="h-3.5 w-3.5" />}
                        </Button>
                        <Button size="sm" variant="ghost" className="text-destructive" onClick={() => {
                          if (confirm("Permanently delete this broadcast?")) {
                            delFn({ data: { id: b.id } }).then(() => qc.invalidateQueries({ queryKey: ["broadcasts"] }));
                          }
                        }}>
                          <Trash2 className="h-3.5 w-3.5" />
                        </Button>
                      </>
                    )}
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}

      {tab === "templates" && (
        <div className="space-y-2">
          {tplQ.isLoading && <div className="flex justify-center py-8"><Loader2 className="h-5 w-5 animate-spin text-muted-foreground" /></div>}
          {!tplQ.isLoading && (tplQ.data ?? []).length === 0 && (
            <div className="rounded-xl border border-dashed border-border p-12 text-center text-sm text-muted-foreground">
              No templates yet. Save one from the Compose tab.
            </div>
          )}
          {(tplQ.data ?? []).map((t: BroadcastTemplate) => (
            <div key={t.id} className="flex items-center gap-3 rounded-xl border border-border bg-card p-4">
              <div className="min-w-0 flex-1">
                <div className="flex items-center gap-2">
                  <h4 className="text-sm font-semibold text-foreground">{t.name}</h4>
                  {t.archived && <span className="rounded bg-muted px-1.5 py-0.5 text-[10px] text-muted-foreground">ARCHIVED</span>}
                </div>
                <p className="truncate text-xs text-muted-foreground">{t.subject}</p>
              </div>
              <Button size="sm" variant="outline" onClick={() => useTemplate(t)}>Use</Button>
              {perms.isSuperAdmin && (
                <>
                  <Button size="sm" variant="ghost" onClick={() => tplArchiveFn({ data: { id: t.id, archived: !t.archived } }).then(() => qc.invalidateQueries({ queryKey: ["broadcasts", "templates"] }))}>
                    {t.archived ? "Restore" : "Archive"}
                  </Button>
                  <Button size="sm" variant="ghost" className="text-destructive" onClick={() => {
                    if (confirm("Delete this template?")) {
                      tplDelFn({ data: { id: t.id } }).then(() => qc.invalidateQueries({ queryKey: ["broadcasts", "templates"] }));
                    }
                  }}>
                    <Trash2 className="h-3.5 w-3.5" />
                  </Button>
                </>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
