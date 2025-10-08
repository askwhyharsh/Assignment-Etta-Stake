import { ethers } from 'ethers';
import { CHAIN_ID_HEX } from '../config/contracts';

export function getWindowEthereum(): any | undefined {
  if (typeof window !== 'undefined') {
    // @ts-ignore
    return window.ethereum;
  }
  return undefined;
}

export async function ensureSepoliaNetwork(): Promise<void> {
  const eth = getWindowEthereum();
  if (!eth) throw new Error('MetaMask not found');
  const currentChainId = await eth.request({ method: 'eth_chainId' });
  if (currentChainId !== CHAIN_ID_HEX) {
    try {
      await eth.request({
        method: 'wallet_switchEthereumChain',
        params: [{ chainId: CHAIN_ID_HEX }],
      });
    } catch (e: any) {
      throw new Error('Please switch to Sepolia in MetaMask');
    }
  }
}

export async function connectWallet(): Promise<string> {
  const eth = getWindowEthereum();
  if (!eth) throw new Error('MetaMask not found');
  await ensureSepoliaNetwork();
  const accounts: string[] = await eth.request({ method: 'eth_requestAccounts' });
  if (!accounts || accounts.length === 0) throw new Error('No account');
  return ethers.getAddress(accounts[0]);
}

export function getProvider(): ethers.BrowserProvider {
  const eth = getWindowEthereum();
  if (!eth) throw new Error('MetaMask not found');
  return new ethers.BrowserProvider(eth);
}

export async function getSigner(): Promise<ethers.Signer> {
  const provider = getProvider();
  return await provider.getSigner();
}
