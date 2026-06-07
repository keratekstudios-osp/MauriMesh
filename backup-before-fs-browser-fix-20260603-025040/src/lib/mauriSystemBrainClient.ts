import {
  evolveSystemBrain,
  getButtonScanReport,
  getSystemBrainSnapshot,
  stressLearnSystemBrain,
} from "../maurimesh/system-brain/systemBrain";

export async function getMauriSystemBrain() {
  return getSystemBrainSnapshot();
}

export async function evolveMauriSystemBrain() {
  return evolveSystemBrain();
}

export async function stressLearnMauriSystemBrain() {
  return stressLearnSystemBrain();
}

export async function getMauriButtonScan() {
  return getButtonScanReport();
}
