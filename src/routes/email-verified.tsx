import { createFileRoute, Link } from "@tanstack/react-router";
import { Check, ArrowRight, MailCheck } from "lucide-react";
import { AuthShell } from "@/components/auth/AuthShell";
import { NeonButton } from "@/components/auth/AuthPrimitives";

export const Route = createFileRoute("/email-verified")({
  component: EmailVerified,
  head: () => ({
    meta: [
      { title: "Email Verified · CA Aspire BD" },
      { name: "description", content: "Your email is verified. Welcome aboard CA Aspire BD." },
      { property: "og:title", content: "Email Verified · CA Aspire BD" },
      {
        property: "og:description",
        content: "You're all set — continue to your personalized dashboard.",
      },
    ],
  }),
});

function Confetti() {
  const pieces = Array.from({ length: 24 });
  return (
    <div className="pointer-events-none absolute inset-0 overflow-hidden">
      {pieces.map((_, i) => {
        const left = (i * 41) % 100;
        const delay = (i % 7) * 0.4;
        const colors = [
          "var(--neon-purple)",
          "var(--neon-blue)",
          "var(--neon-pink)",
          "#34d399",
          "#fbbf24",
        ];
        return (
          <span
            key={i}
            className="absolute h-2 w-2 rounded-sm animate-float"
            style={{
              left: `${left}%`,
              top: `${(i * 23) % 80}%`,
              background: colors[i % colors.length],
              boxShadow: `0 0 10px ${colors[i % colors.length]}`,
              animationDelay: `${delay}s`,
              transform: `rotate(${(i * 37) % 360}deg)`,
            }}
          />
        );
      })}
    </div>
  );
}

function EmailVerified() {
  return (
    <AuthShell>
      <div className="relative py-4 text-center">
        <Confetti />
        <div className="relative mx-auto grid h-24 w-24 place-items-center">
          <div
            className="absolute inset-0 rounded-full opacity-70 blur-2xl animate-pulse-glow"
            style={{ background: "var(--neon-purple)" }}
          />
          <div className="absolute inset-2 rounded-full border-2 border-[var(--neon-blue)]/40" />
          <div className="absolute inset-5 rounded-full border-2 border-[var(--neon-purple)]/60" />
          <div className="relative grid h-16 w-16 place-items-center rounded-full bg-gradient-to-br from-emerald-400 via-[var(--neon-blue)] to-[var(--neon-purple)] text-white shadow-[0_0_40px_var(--neon-purple)] animate-scale-in">
            <Check className="h-8 w-8" strokeWidth={3} />
          </div>
        </div>

        <h2 className="mt-6 font-display text-3xl font-bold tracking-tight">Email verified!</h2>
        <p className="mx-auto mt-2 max-w-xs text-sm text-muted-foreground">
          Your account is now active. Step into your AI-personalized learning command deck.
        </p>

        <div className="mx-auto mt-5 flex items-center justify-center gap-2 rounded-full border border-emerald-400/30 bg-emerald-400/10 px-3 py-1.5 text-[11px] font-semibold text-emerald-400">
          <MailCheck className="h-3.5 w-3.5" /> you@school.edu · confirmed
        </div>

        <div className="mt-7 space-y-3">
          <Link to="/dashboard">
            <NeonButton>
              Continue to dashboard <ArrowRight className="h-4 w-4" />
            </NeonButton>
          </Link>
          <Link
            to="/login"
            className="block text-xs font-semibold text-muted-foreground hover:text-[var(--neon-blue)]"
          >
            or return to sign in
          </Link>
        </div>
      </div>
    </AuthShell>
  );
}
