import { MeshNode } from "./types";

export type CommunityProfile = {
  id: string;
  name: string;
  purpose:
    | "FAMILY"
    | "IWI"
    | "SCHOOL"
    | "HOSPITAL"
    | "SECURITY"
    | "EMERGENCY"
    | "RURAL"
    | "PUBLIC_GOOD";
  guardians: string[];
  allowedRelays: string[];
};

export class CommunityInfrastructure {
  private communities = new Map<string, CommunityProfile>();

  createCommunity(profile: CommunityProfile): CommunityProfile {
    this.communities.set(profile.id, profile);
    return profile;
  }

  canNodeServeCommunity(node: MeshNode, communityId: string): boolean {
    const community = this.communities.get(communityId);
    if (!community) return false;

    if (node.trust === "BLOCKED") return false;
    if (community.guardians.includes(node.id)) return true;
    if (community.allowedRelays.includes(node.id)) return true;

    return node.role === "GATEWAY" || node.role === "SUPERNODE";
  }

  listCommunities(): CommunityProfile[] {
    return Array.from(this.communities.values());
  }
}
