import { Link, useLocation } from "wouter";
import { MessageSquare, Settings } from "lucide-react";
import { motion, AnimatePresence } from "framer-motion";
import { ReactNode } from "react";

interface LayoutProps {
  children: ReactNode;
}

export default function Layout({ children }: LayoutProps) {
  const [location] = useLocation();

  const navItems = [
    { path: "/", icon: MessageSquare, label: "Chat" },
    { path: "/settings", icon: Settings, label: "Settings" },
  ];

  return (
    <div className="flex flex-col h-[100dvh] bg-background text-foreground overflow-hidden w-full max-w-md mx-auto border-x border-border/40 relative shadow-2xl">
      {/* Subtle top gradient for depth */}
      <div className="absolute top-0 left-0 right-0 h-32 bg-gradient-to-b from-primary/5 to-transparent pointer-events-none z-0" />
      
      {/* Main Content Area */}
      <main className="flex-1 overflow-hidden relative z-10">
        <AnimatePresence mode="wait">
          <motion.div
            key={location}
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -10 }}
            transition={{ duration: 0.2 }}
            className="h-full"
          >
            {children}
          </motion.div>
        </AnimatePresence>
      </main>

      {/* Bottom Navigation */}
      <nav className="h-16 border-t border-border/50 bg-card/80 backdrop-blur-xl pb-safe z-50 flex items-center justify-around px-2 shrink-0">
        {navItems.map((item) => {
          const isActive = location === item.path;
          const Icon = item.icon;
          
          return (
            <Link key={item.path} href={item.path}>
              <a 
                className={`flex flex-col items-center justify-center w-16 h-14 rounded-2xl transition-all duration-200 ${
                  isActive ? "text-primary" : "text-muted-foreground hover:text-foreground"
                }`}
                data-testid={`nav-${item.label.toLowerCase()}`}
              >
                <div className="relative">
                  <Icon size={22} strokeWidth={isActive ? 2.5 : 2} />
                  {isActive && (
                    <motion.div 
                      layoutId="nav-indicator"
                      className="absolute -bottom-4 left-1/2 -translate-x-1/2 w-1 h-1 bg-primary rounded-full shadow-[0_0_8px_rgba(20,184,102,0.8)]"
                      transition={{ type: "spring", bounce: 0.3, duration: 0.5 }}
                    />
                  )}
                </div>
                <span className="text-[10px] font-medium mt-1.5 opacity-80">{item.label}</span>
              </a>
            </Link>
          );
        })}
      </nav>
    </div>
  );
}