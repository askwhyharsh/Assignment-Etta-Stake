import React from 'react';
import { connectWallet, getWindowEthereum } from '../lib/eth';

type Props = {
  account: string | null;
  setAccount: (a: string | null) => void;
};

export default function ConnectWallet({ account, setAccount }: Props) {
  const onConnect = async () => {
    try {
      const addr = await connectWallet();
      setAccount(addr);
    } catch (e: any) {
      alert(e.message ?? String(e));
    }
  };

  const eth = getWindowEthereum();
  const installed = Boolean(eth);

  return (
    <div className="flex items-center gap-3">
      {account ? (
        <span className="px-3 py-1 rounded bg-green-100 text-green-800 text-sm">
          {account.slice(0, 6)}...{account.slice(-4)}
        </span>
      ) : (
        <button onClick={onConnect} className="px-4 py-2 bg-indigo-600 text-white rounded hover:bg-indigo-700">
          Connect Wallet
        </button>
      )}
      {!installed && (
        <a className="text-sm text-blue-600 underline" href="https://metamask.io" target="_blank" rel="noreferrer">
          Install MetaMask
        </a>
      )}
    </div>
  );
}
