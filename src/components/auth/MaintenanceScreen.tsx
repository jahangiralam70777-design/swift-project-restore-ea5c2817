import { useEffect, useState } from "react";
import { Link } from "@tanstack/react-router";
import { ShieldAlert, Clock } from "lucide-react";
import { AuthShell } from "@/components/auth/AuthShell";

type Props = {
  title: string;
  subtitle: string;
  description: string;
  footer: string;
  autoEnableAt: string | null;
};

function useCountdown(target: string | null) {
  const [now, setNow] = useState(() => Date.now());
  useEffect(() => {
    if (!target) return;
    const id = window.setInterval(() => setNow(Date.now()), 1000);
    return () => window.clearInterval(id);
  }, [target]);
  if (!target) return null;
  const diff = new Date(target).getTime() - now;
  if (diff <= 0) return { d: 0, h: 0, m: 0, s: 0, done: true };
  const s = Math.floor(diff / 1000);
  return {
    d: Math.floor(s / 86400),
    h: Math.floor((s % 86400) / 3600),
    m: Math.floor((s % 3600) / 60),
    s: s % 60,
    done: false,
  };
}

function Cell({ label, value }: { label: string; value: number }) {
  return (
    <div className="flex flex-col items-center rounded-xl border border-border bg-background/40 px-4 py-3 min-w-[68px]">
      <span className="font-mono text-2xl font-bold tabular-nums">
        {String(value).padStart(2, "0")}
      </span>
      <span className="mt-0.5 text-[10px] uppercase tracking-widest text-muted-foreground">
        {label}
      </span>
    </div>
  );
}

export function MaintenanceScreen({
  title,
  subtitle,
  description,
  footer,
  autoEnableAt,
}: Props) {
  const cd = useCountdown(autoEnableAt);
  return (
    <AuthShell variant="student">
      <div className="flex items-center gap-3">
        <div className="flex h-11 w-11 items-center justify-center rounded-xl border border-amber-500/40 bg-amber-500/10 text-amber-400">
          <ShieldAlert className="h-5 w-5" />
        </div>
        <div>
          <p className="text-[11px] font-semibold uppercase tracking-widest text-amber-400">
            {subtitle}
          </p>
          <h2 className="font-display text-2xl font-bold tracking-tight">{title}</h2>
        </div>
      </div>

      <p className="mt-5 text-sm leading-relaxed text-muted-foreground whitespace-pre-line">
        {description}
      </p>

      {autoEnableAt && (
        <div className="mt-6 rounded-2xl border border-border bg-muted/30 p-4">
          <div className="flex items-center gap-2 text-xs font-medium text-muted-foreground">
            <Clock className="h-3.5 w-3.5" /> Service resumes on{" "}
            <span className="font-mono text-foreground">
              {new Date(autoEnableAt).toLocaleString()}
            </span>
          </div>
          {cd && !cd.done && (
            <div className="mt-3 flex flex-wrap gap-2">
              <Cell label="Days" value={cd.d} />
              <Cell label="Hours" value={cd.h} />
              <Cell label="Minutes" value={cd.m} />
              <Cell label="Seconds" value={cd.s} />
            </div>
          )}
        </div>
      )}

      <p className="mt-6 text-center text-xs text-muted-foreground">{footer}</p>

      <p className="mt-4 text-center text-xs">
        <Link to="/" className="font-semibold text-[var(--neon-blue)] hover:underline">
          Return to homepage
        </Link>
      </p>
    </AuthShell>
  );
}