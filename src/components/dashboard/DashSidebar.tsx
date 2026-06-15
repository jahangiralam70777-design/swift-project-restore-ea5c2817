import { Link, useRouterState } from "@tanstack/react-router";
import { GraduationCap, X } from "lucide-react";
import { studentNavItems } from "@/lib/app-data";
import { useAppStore } from "@/stores/app-store";
import { useModuleVisibility } from "@/hooks/use-module-visibility";
import { DashSidebarFooter } from "./DashSidebarFooter";

export function DashSidebar() {
  const currentPath = useRouterState({ select: (s) => s.location.pathname });
  const sidebarOpen = useAppStore((s) => s.sidebarOpen);
  const setSidebarOpen = useAppStore((s) => s.setSidebarOpen);
  const { isPathHidden } = useModuleVisibility();
  const visibleItems = studentNavItems.filter((item) => !isPathHidden(item.to));
  const learningItems = visibleItems.filter((i) => !["Notifications", "Profile"].includes(i.title));
  const accountItems = visibleItems.filter((i) => ["Notifications", "Profile"].includes(i.title));
  const SidebarContent = ({ mobile = false }: { mobile?: boolean }) => (
    <>
      <Link
        to="/"
        onClick={() => mobile && setSidebarOpen(false)}
        className="flex items-center gap-2 px-2 py-2"
      >
        <div className="bg-cta-gradient flex h-9 w-9 items-center justify-center rounded-xl shadow-glow">
          <GraduationCap className="h-5 w-5 text-white" />
        </div>
        <span className="font-display text-base font-bold tracking-tight">
          CA Aspire BD<span className="text-gradient"> Pro</span>
        </span>
      </Link>

      <nav className="mt-6 flex-1 overflow-y-auto">
        <p className="px-3 text-[10px] font-semibold uppercase tracking-widest text-muted-foreground">
          Learning
        </p>
        <ul className="mt-2 space-y-1">
          {learningItems.map((m) => {
            const isActive = currentPath === m.to;
            return (
              <li key={m.title}>
                <Link
                  to={m.to as never}
                  activeOptions={{ exact: true }}
                  onClick={() => mobile && setSidebarOpen(false)}
                  aria-current={isActive ? "page" : undefined}
                  className={`group relative flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm transition-all ${
                    isActive
                      ? "bg-cta-gradient text-white shadow-glow"
                      : "text-foreground/80 hover:bg-muted hover:text-foreground"
                  }`}
                >
                  <m.icon className="h-4 w-4" />
                  {m.title}
                  {isActive && (
                    <span className="ml-auto h-1.5 w-1.5 rounded-full bg-white shadow-[0_0_8px_white]" />
                  )}
                </Link>
              </li>
            );
          })}
        </ul>

        <p className="mt-6 px-3 text-[10px] font-semibold uppercase tracking-widest text-muted-foreground">
          Account
        </p>
        <ul className="mt-2 space-y-1">
          {accountItems.map((s) => {
            const isActive = currentPath === s.to;
            return (
              <li key={s.title}>
                <Link
                  to={s.to as never}
                  activeOptions={{ exact: true }}
                  onClick={() => mobile && setSidebarOpen(false)}
                  aria-current={isActive ? "page" : undefined}
                  className={`flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm transition-colors ${
                    isActive
                      ? "bg-cta-gradient text-white shadow-glow"
                      : "text-foreground/80 hover:bg-muted hover:text-foreground"
                  }`}
                >
                  <s.icon className="h-4 w-4" />
                  {s.title}
                </Link>
              </li>
            );
          })}
        </ul>
      </nav>
      <DashSidebarFooter onNavigate={() => mobile && setSidebarOpen(false)} />
    </>
  );
  return (
    <>
      {sidebarOpen && (
        <div className="fixed inset-0 z-50 lg:hidden">
          <button
            aria-label="Close menu"
            className="absolute inset-0 bg-background/70 backdrop-blur-sm"
            onClick={() => setSidebarOpen(false)}
          />
          <aside className="glass shadow-card-soft pointer-events-auto relative z-10 flex h-full w-72 max-w-[85vw] flex-col p-4">
            <button
              aria-label="Close menu"
              onClick={() => setSidebarOpen(false)}
              className="absolute right-3 top-3 rounded-xl p-2 text-muted-foreground hover:bg-muted hover:text-foreground"
            >
              <X className="h-4 w-4" />
            </button>
            <SidebarContent mobile />
          </aside>
        </div>
      )}
      <aside className="glass shadow-card-soft sticky top-4 hidden h-[calc(100vh-2rem)] w-64 shrink-0 flex-col rounded-3xl p-4 lg:flex">
        <SidebarContent />
      </aside>
    </>
  );
}
