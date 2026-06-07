import { useState, useEffect, useRef } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { Send, Image as ImageIcon, Mic, MoreVertical, Check, CheckCheck, WifiOff, Phone } from "lucide-react";
import { Avatar, AvatarImage, AvatarFallback } from "@/components/ui/avatar";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { ScrollArea } from "@/components/ui/scroll-area";
import { useQuery, useMutation } from "@tanstack/react-query";
import { mauriMeshBridge } from "@/lib/maurimesh-client";

interface Message {
  id: string;
  text: string;
  sender: "me" | "other";
  senderId?: string;
  timestamp: string;
  status: "sent" | "delivered" | "read";
  isEncrypted?: boolean;
  timeMs: number;
}

export default function Messenger() {
  const [localMessages, setLocalMessages] = useState<Message[]>([]);
  const [inputValue, setInputValue] = useState("");
  const [myNodeId] = useState("Frontend_User");
  const [targetNodeId, setTargetNodeId] = useState("BROADCAST");
  const endOfMessagesRef = useRef<HTMLDivElement>(null);

  const { data: nodes, isError } = useQuery({
    queryKey: ['mesh-nodes'],
    queryFn: () => mauriMeshBridge.nodes(),
    refetchInterval: 2000,
  });

  const sendMessageMutation = useMutation({
    mutationFn: (text: string) => mauriMeshBridge.sendMessengerText({
      fromNode: myNodeId,
      toNode: targetNodeId,
      text,
    }),
  });

  const handleCall = async () => {
    const callId = `call_${Date.now()}`;
    try {
      await mauriMeshBridge.sendMessengerText({
        fromNode: myNodeId,
        toNode: targetNodeId,
        text: JSON.stringify({
          type: "CALL_INVITE",
          callId,
          mode: "audio",
          from: myNodeId,
          timestamp: Date.now(),
        }),
      });
      
      const newMessage: Message = {
        id: Date.now().toString(),
        text: "📞 Initiating audio call...",
        sender: "me",
        timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
        status: "sent",
        timeMs: Date.now(),
      };
      setLocalMessages(prev => [...prev, newMessage]);
    } catch (error) {
      console.error("Failed to send call invite:", error);
    }
  };

  const handleSend = (e: React.FormEvent) => {
    e.preventDefault();
    if (!inputValue.trim()) return;

    const text = inputValue.trim();
    const now = Date.now();

    const newMessage: Message = {
      id: now.toString(),
      text,
      sender: "me",
      timestamp: new Date(now).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      status: "sent",
      isEncrypted: true,
      timeMs: now,
    };

    setLocalMessages(prev => [...prev, newMessage]);
    setInputValue("");

    sendMessageMutation.mutate(text, {
      onSuccess: () => {
        setLocalMessages(prev => 
          prev.map(msg => msg.id === newMessage.id ? { ...msg, status: "delivered" } : msg)
        );
      },
    });
  };

  // Combine local messages and remote received messages
  const remoteMessages: Message[] = [];
  if (nodes) {
    const myNode = nodes.find(n => n.nodeId === myNodeId);
    const inbox = myNode?.receivedMessages ?? [];
    
    inbox.forEach(msg => {
      // Skip our own broadcast messages coming back to us
      if (msg.senderId !== myNodeId) {
        remoteMessages.push({
          id: msg.id,
          text: msg.payload,
          sender: "other",
          senderId: msg.senderId,
          timestamp: new Date(msg.timestamp || Date.now()).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
          status: "delivered",
          isEncrypted: true,
          timeMs: msg.timestamp || Date.now(),
        });
      }
    });
  }

  // Deduplicate and sort all messages by time
  const allMessages = [...localMessages, ...remoteMessages]
    .filter((msg, index, self) => index === self.findIndex((m) => m.id === msg.id))
    .sort((a, b) => a.timeMs - b.timeMs);

  useEffect(() => {
    endOfMessagesRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [allMessages.length]);

  return (
    <div className="flex flex-col h-full bg-background relative scanlines">
      {/* Header */}
      <header className="h-16 flex items-center justify-between px-4 border-b border-border/40 bg-background/80 backdrop-blur-xl z-20 shrink-0">
        <div className="flex items-center gap-3">
          <div className="relative">
            <Avatar className="h-10 w-10 ring-2 ring-primary/20">
              <AvatarImage src="https://api.dicebear.com/7.x/avataaars/svg?seed=NodeAlpha&backgroundColor=14b866" />
              <AvatarFallback>NW</AvatarFallback>
            </Avatar>
            <div className={`absolute bottom-0 right-0 w-3 h-3 rounded-full ring-2 ring-background ${isError ? "bg-destructive" : "bg-primary"}`} />
          </div>
          <div>
            <h2 className="font-semibold text-foreground text-sm tracking-tight">MauriMesh Network</h2>
            <div className="flex items-center gap-1.5">
              {isError ? (
                <>
                  <WifiOff size={10} className="text-destructive" />
                  <span className="text-xs text-destructive font-mono">Connection Lost</span>
                </>
              ) : (
                <>
                  <div className="w-1.5 h-1.5 rounded-full bg-primary animate-pulse" />
                  <span className="text-xs text-primary font-mono">
                    {nodes ? `${nodes.length} Node(s) Active` : "Connecting..."}
                  </span>
                </>
              )}
            </div>
          </div>
        </div>
        <div className="flex items-center gap-1">
          <Button variant="ghost" size="icon" className="text-muted-foreground hover:text-primary rounded-full" onClick={handleCall} data-testid="button-call">
            <Phone size={20} />
          </Button>
          <Button variant="ghost" size="icon" className="text-muted-foreground hover:text-foreground rounded-full">
            <MoreVertical size={20} />
          </Button>
        </div>
      </header>

      {/* Message List */}
      <ScrollArea className="flex-1 px-4 py-6 z-10">
        <div className="flex flex-col gap-4 pb-20">
          <AnimatePresence initial={false}>
            {allMessages.map((msg) => (
              <motion.div
                key={msg.id}
                initial={{ opacity: 0, y: 10, scale: 0.95 }}
                animate={{ opacity: 1, y: 0, scale: 1 }}
                layout
                className={`flex flex-col max-w-[85%] ${msg.sender === "me" ? "self-end items-end" : "self-start items-start"}`}
              >
                <div 
                  className={`
                    px-4 py-2.5 rounded-2xl relative overflow-hidden backdrop-blur-md
                    ${msg.sender === "me" 
                      ? "bg-primary/10 text-primary-foreground border border-primary/20 rounded-br-sm" 
                      : "bg-card text-card-foreground border border-border/50 rounded-bl-sm"}
                  `}
                >
                  {/* Subtle noise texture overlay */}
                  <div className="absolute inset-0 opacity-[0.03] pointer-events-none mix-blend-overlay" style={{ backgroundImage: 'url("data:image/svg+xml,%3Csvg viewBox=%220 0 200 200%22 xmlns=%22http://www.w3.org/2000/svg%22%3E%3Cfilter id=%22noiseFilter%22%3E%3CfeTurbulence type=%22fractalNoise%22 baseFrequency=%220.65%22 numOctaves=%223%22 stitchTiles=%22stitch%22/%3E%3C/filter%3E%3Crect width=%22100%25%22 height=%22100%25%22 filter=%22url(%23noiseFilter)%22/%3E%3C/svg%3E")' }} />
                  
                  {msg.sender === "other" && msg.senderId && (
                    <div className="text-[10px] font-semibold text-muted-foreground mb-1 uppercase tracking-wider">
                      {msg.senderId}
                    </div>
                  )}
                  <p className="text-[15px] leading-relaxed relative z-10">{msg.text}</p>
                </div>
                
                <div className="flex items-center gap-1.5 mt-1 px-1">
                  <span className="text-[10px] text-muted-foreground font-mono">{msg.timestamp}</span>
                  {msg.sender === "me" && (
                    <span className="text-primary/70">
                      {msg.status === "sent" && <Check size={12} />}
                      {msg.status === "delivered" && <CheckCheck size={12} />}
                      {msg.status === "read" && <CheckCheck size={12} className="text-primary" />}
                    </span>
                  )}
                </div>
              </motion.div>
            ))}
          </AnimatePresence>
          <div ref={endOfMessagesRef} />
        </div>
      </ScrollArea>

      {/* Input Area */}
      <div className="p-4 bg-background/80 backdrop-blur-xl border-t border-border/40 z-20 shrink-0 pb-safe">
        <form onSubmit={handleSend} className="flex items-end gap-2 relative">
          <div className="flex-1 relative bg-card/50 rounded-2xl border border-border/50 focus-within:border-primary/50 focus-within:ring-1 focus-within:ring-primary/50 transition-all flex items-center shadow-sm">
            <Button type="button" variant="ghost" size="icon" className="rounded-full h-10 w-10 shrink-0 text-muted-foreground hover:text-foreground ml-1">
              <ImageIcon size={20} />
            </Button>
            
            <Input 
              value={inputValue}
              onChange={(e) => setInputValue(e.target.value)}
              placeholder="Secure message..." 
              className="border-0 bg-transparent shadow-none focus-visible:ring-0 px-2 py-6 text-[15px]"
              data-testid="input-message"
              disabled={sendMessageMutation.isPending}
            />
            
            {!inputValue.trim() && (
              <Button type="button" variant="ghost" size="icon" className="rounded-full h-10 w-10 shrink-0 text-muted-foreground hover:text-foreground mr-1">
                <Mic size={20} />
              </Button>
            )}
          </div>
          
          <AnimatePresence>
            {inputValue.trim() && (
              <motion.div
                initial={{ opacity: 0, scale: 0.8, width: 0 }}
                animate={{ opacity: 1, scale: 1, width: "auto" }}
                exit={{ opacity: 0, scale: 0.8, width: 0 }}
                transition={{ type: "spring", bounce: 0.4 }}
              >
                <Button 
                  type="submit" 
                  size="icon" 
                  className="rounded-full h-12 w-12 bg-primary hover:bg-primary/90 text-primary-foreground shadow-lg shadow-primary/20"
                  data-testid="button-send"
                  disabled={sendMessageMutation.isPending}
                >
                  <Send size={20} className="ml-0.5" />
                </Button>
              </motion.div>
            )}
          </AnimatePresence>
        </form>
      </div>
    </div>
  );
}