import { createFileRoute, Link, useNavigate } from "@tanstack/react-router";
import { useEffect, useState } from "react";
import { KeyRound, ShieldCheck } from "lucide-react";
import { toast } from "sonner";
import { AuthShell } from "@/components/auth/AuthShell";
import {
  PasswordInput,
  NeonButton,
  FieldLabel,
  StrengthMeter,
  Requirements,
} from "@/components/auth/AuthPrimitives";
import { updatePassword } from "@/lib/auth-client";

export const Route = createFileRoute("/reset-password")({
  component: ResetPassword,
  head: () => ({
    meta: [
      { title: "Create New Password · CA Aspire BD" },
      { name: "description", content: "Set a new password and secure your CA Aspire BD account." },
      { property: "og:title", content: "Create New Password · CA Aspire BD" },
      {
        property: "og:description",
        content: "Strong password requirements with real-time strength feedback.",
      },
    ],
  }),
});

function ResetPassword() {
  const [pw, setPw] = useState("");
  const [pw2, setPw2] = useState("");
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();
  const match = pw.length > 0 && pw === pw2;

  // A-8: only allow access when a Supabase recovery token is present.
  // Supabase delivers the recovery flow via the URL hash fragment
  // (#access_token=...&type=recovery). Without it, redirect to /login.
  useEffect(() => {
    if (typeof window === "undefined") return;
    const hash = window.location.hash || "";
    if (!hash.includes("type=recovery")) {
      navigate({ to: "/login", replace: true });
    }
  }, [navigate]);

  const onSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (pw.length < 8) return toast.error("Password must be at least 8 characters");
    if (!match) return toast.error("Passwords do not match");
    setLoading(true);
    try {
      await updatePassword(pw);
      toast.success("Password updated. Please sign in.");
      navigate({ to: "/login" });
    } catch (err) {
      toast.error((err as Error).message ?? "Could not update password");
    } finally {
      setLoading(false);
    }
  };

  return (
    <AuthShell>
      <div className="mx-auto mb-4 grid h-14 w-14 place-items-center rounded-2xl bg-gradient-to-br from-[var(--neon-purple)] to-[var(--neon-blue)] text-white shadow-[0_0_30px_var(--neon-purple)]">
        <KeyRound className="h-6 w-6" />
      </div>
      <h2 className="text-center font-display text-3xl font-bold tracking-tight">
        Create new password
      </h2>
      <p className="mt-1.5 text-center text-sm text-muted-foreground">
        Choose a strong password to re-secure your account.
      </p>

      <form className="mt-7 space-y-4" onSubmit={onSubmit}>
        <div>
          <FieldLabel htmlFor="reset-password-new">New password</FieldLabel>
          <PasswordInput
            id="reset-password-new"
            name="new-password"
            autoComplete="new-password"
            value={pw}
            onChange={setPw}
          />
          <StrengthMeter value={pw} />
        </div>
        <div>
          <FieldLabel htmlFor="reset-password-confirm">Confirm password</FieldLabel>
          <PasswordInput
            id="reset-password-confirm"
            name="confirm-password"
            autoComplete="new-password"
            value={pw2}
            onChange={setPw2}
          />
          {pw2.length > 0 && (
            <p
              id="reset-password-match"
              aria-live="polite"
              className={`mt-1 text-[11px] ${match ? "text-emerald-400" : "text-rose-400"}`}
            >
              {match ? "Passwords match." : "Passwords do not match."}
            </p>
          )}
        </div>

        <div className="rounded-2xl border border-border bg-muted/30 p-3">
          <div className="flex items-center gap-1.5 text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">
            <ShieldCheck className="h-3 w-3 text-[var(--neon-purple)]" /> Security checklist
          </div>
          <Requirements value={pw} />
        </div>

        <NeonButton type="submit" disabled={loading}>
          {loading ? "Updating…" : "Reset password"}
        </NeonButton>
      </form>

      <p className="mt-6 text-center text-xs text-muted-foreground">
        Remembered it?{" "}
        <Link to="/login" className="font-semibold text-[var(--neon-blue)] hover:underline">
          Back to sign in
        </Link>
      </p>
    </AuthShell>
  );
}
