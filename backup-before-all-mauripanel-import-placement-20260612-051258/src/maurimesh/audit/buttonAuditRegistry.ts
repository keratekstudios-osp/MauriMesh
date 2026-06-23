export type AuditRoute = {
  title: string;
  route: string;
  auditId: string;
  expected: string;
  risk: "LOW" | "MEDIUM" | "HIGH";
};

export const MAURIMESH_AUDIT_ROUTES: AuditRoute[] = [
  {
    title: "Dashboard",
    route: "/dashboard",
    auditId: "route_dashboard",
    expected: "Dashboard opens without crash.",
    risk: "LOW",
  },
  {
    title: "BLE 2-Hop Proof",
    route: "/ble-2-hop-proof",
    auditId: "route_ble_2_hop_proof",
    expected: "2-hop proof archive screen opens.",
    risk: "LOW",
  },
  {
    title: "BLE 3-Device Proof",
    route: "/ble-3-device-proof",
    auditId: "route_ble_3_device_proof",
    expected: "Safe 3-device proof screen opens and shows build marker.",
    risk: "HIGH",
  },
  {
    title: "Store-Forward Proof",
    route: "/store-forward-proof",
    auditId: "route_store_forward_proof",
    expected: "Store-forward delay proof screen opens.",
    risk: "HIGH",
  },
  {
    title: "Next Proof Exam",
    route: "/next-proof-exam",
    auditId: "route_next_proof_exam",
    expected: "Next proof exam opens.",
    risk: "MEDIUM",
  },
  {
    title: "Chat",
    route: "/chat",
    auditId: "route_chat",
    expected: "Chat screen opens.",
    risk: "LOW",
  },
  {
    title: "Living Mesh",
    route: "/living-mesh",
    auditId: "route_living_mesh",
    expected: "Living mesh screen opens.",
    risk: "MEDIUM",
  },
  {
    title: "Mesh Status",
    route: "/mesh-status",
    auditId: "route_mesh_status",
    expected: "Mesh status screen opens.",
    risk: "LOW",
  },
  {
    title: "Add Friend",
    route: "/add-friend",
    auditId: "route_add_friend",
    expected: "Add friend screen opens.",
    risk: "MEDIUM",
  },
  {
    title: "Pixel Calling",
    route: "/pixel-calling",
    auditId: "route_pixel_calling",
    expected: "Pixel calling UI shell opens.",
    risk: "MEDIUM",
  },
  {
    title: "Settings",
    route: "/settings",
    auditId: "route_settings",
    expected: "Settings opens.",
    risk: "LOW",
  },
];
