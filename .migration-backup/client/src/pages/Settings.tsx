import { motion } from "framer-motion";
import { Settings2, Smartphone, ShieldAlert, Cpu, Database, ChevronRight, Power } from "lucide-react";
import { Switch } from "@/components/ui/switch";
import { Label } from "@/components/ui/label";

export default function Settings() {
  const containerVariants = {
    hidden: { opacity: 0 },
    show: {
      opacity: 1,
      transition: { staggerChildren: 0.05 }
    }
  };

  const itemVariants = {
    hidden: { opacity: 0, x: -10 },
    show: { opacity: 1, x: 0 }
  };

  const Section = ({ title, children }: { title: string, children: React.ReactNode }) => (
    <div className="space-y-3">
      <h3 className="text-[11px] font-bold text-muted-foreground uppercase tracking-widest px-4">{title}</h3>
      <div className="bg-card/40 border-y sm:border sm:rounded-2xl border-border/40 backdrop-blur-sm divide-y divide-border/20 overflow-hidden">
        {children}
      </div>
    </div>
  );

  const SettingRow = ({ icon: Icon, title, description, control }: any) => (
    <motion.div variants={itemVariants} className="flex items-center justify-between p-4 bg-transparent hover:bg-white/5 transition-colors">
      <div className="flex items-center gap-4">
        <div className="p-2 rounded-xl bg-secondary text-foreground">
          <Icon size={18} />
        </div>
        <div className="flex flex-col">
          <span className="text-sm font-medium text-foreground">{title}</span>
          {description && <span className="text-xs text-muted-foreground">{description}</span>}
        </div>
      </div>
      <div className="ml-4 flex-shrink-0">
        {control || <ChevronRight size={16} className="text-muted-foreground" />}
      </div>
    </motion.div>
  );

  return (
    <div className="flex flex-col h-full bg-background scanlines overflow-y-auto pb-24">
      <header className="pt-12 pb-6 px-6 sticky top-0 bg-background/90 backdrop-blur-md z-20 border-b border-border/40">
        <h1 className="text-2xl font-bold tracking-tight text-foreground flex items-center gap-2">
          <Settings2 className="text-primary" />
          Configuration
        </h1>
        <p className="text-sm text-muted-foreground mt-1 font-mono">System parameters</p>
      </header>

      <motion.div 
        variants={containerVariants}
        initial="hidden"
        animate="show"
        className="py-6 space-y-8"
      >
        
        <Section title="Radio Hardware">
          <SettingRow 
            icon={Smartphone} 
            title="BLE Transceiver" 
            description="Primary short-range transport"
            control={<Switch defaultChecked id="ble-switch" />}
          />
          <SettingRow 
            icon={Power} 
            title="High Tx Power" 
            description="Increases range, drains battery"
            control={<Switch id="power-switch" />}
          />
        </Section>

        <Section title="Routing & Security">
          <SettingRow 
            icon={Cpu} 
            title="Hybrid Routing" 
            description="Auto-failover to LoRa"
            control={<Switch defaultChecked id="hybrid-switch" />}
          />
          <SettingRow 
            icon={ShieldAlert} 
            title="Strict Mode" 
            description="Drop unverified packets"
            control={<Switch defaultChecked id="strict-switch" />}
          />
        </Section>

        <Section title="System">
          <SettingRow 
            icon={Database} 
            title="Local Storage" 
            description="Manage message retention"
          />
          <SettingRow 
            icon={Activity} 
            title="Export Diagnostic Logs" 
          />
        </Section>
        
        {/* Footer Info */}
        <div className="px-4 py-4 text-center">
          <p className="text-xs font-mono text-muted-foreground opacity-60">MauriMesh Core v1.4.2-alpha</p>
          <p className="text-[10px] font-mono text-muted-foreground/40 mt-1">Built for resilience</p>
        </div>

      </motion.div>
    </div>
  );
}

function Activity(props: any) {
  return <svg {...props} xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M22 12h-4l-3 9L9 3l-3 9H2"/></svg>
}