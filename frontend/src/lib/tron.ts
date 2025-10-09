import TronWeb from 'tronweb';

// Define the TronWeb instance type
type TronWebInstance = any;

// Define extended Window interface
interface TronWebWindow extends Window {
  tronWeb?: TronWebInstance;
  tronLink?: {
    ready?: boolean;
    request?: (args: { method: string }) => Promise<any>;
  };
}

export function getWindowTron(): TronWebInstance | undefined {
  if (typeof window !== 'undefined') {
    return (window as TronWebWindow).tronWeb;
  }
  return undefined;
}

export function getWindowTronLink(): any | undefined {
  if (typeof window !== 'undefined') {
    return (window as TronWebWindow).tronLink;
  }
  return undefined;
}

export async function connectTronLink(): Promise<string> {
  const tronLink = getWindowTronLink();
  if (!tronLink) throw new Error('TronLink not found');

  // Newer TronLink exposes a request API similar to EIP-1193
  if (typeof tronLink.request === 'function') {
    try {
      await tronLink.request({ method: 'tron_requestAccounts' });
    } catch (e: any) {
      throw new Error(e?.message || 'Failed to connect TronLink');
    }
  }

  // Wait until tronWeb is injected and ready
  const tronWeb = await waitForTronWebReady(8000);
  if (!tronWeb.defaultAddress?.base58) throw new Error('No Tron account found');
  return tronWeb.defaultAddress.base58 as string;
}

export async function waitForTronWebReady(timeoutMs: number = 8000): Promise<TronWebInstance> {
  const start = Date.now();
  while (Date.now() - start < timeoutMs) {
    const tw = getWindowTron();
    const ready = tw && (tw as any).ready;
    if (tw && ready) return tw;
    await new Promise((r) => setTimeout(r, 100));
  }
  throw new Error('TronWeb not ready');
}

export async function getTronWeb(): Promise<TronWebInstance> {
  return await waitForTronWebReady();
}

export function isShastaNetwork(tronWeb: TronWebInstance): boolean {
  try {
    const host = (tronWeb.fullNode as any)?.host || '';
    return typeof host === 'string' && host.includes('shasta');
  } catch {
    return false;
  }
}