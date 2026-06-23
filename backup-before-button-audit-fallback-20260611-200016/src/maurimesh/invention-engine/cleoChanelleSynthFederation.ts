import { EngineResult, SynthMessage } from "./types";

export class CleoChanelleSynthFederation {
  explain(result: EngineResult): SynthMessage[] {
    const messages: SynthMessage[] = [];

    messages.push({
      agent: "CLEO_SYNTH",
      tone: "calm",
      text: `Packet ${result.packet.id} was checked by governance: ${result.governance.reason}`,
    });

    messages.push({
      agent: "CHANELLE_SYNTH",
      tone: result.packet.culturalState === "KIA_KAHA_EMERGENCY" ? "emergency" : "educational",
      text: result.routePlan.storeAndForward
        ? "The message can be safely stored and forwarded when the next trusted path appears."
        : "A direct route is available now, so the message can move immediately.",
    });

    if (!result.governance.approved) {
      messages.push({
        agent: "CLEO_SYNTH",
        tone: "protective",
        text: "This message was stopped because the safety rules did not approve the route.",
      });
    }

    return messages;
  }
}
