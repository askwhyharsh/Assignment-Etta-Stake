import React from 'react';
import { mintFromPack, userPackBalance, getPack } from '../lib/stakeContract';

type Props = { account: string | null };

export default function MintPage({ account }: Props) {
  const [packId, setPackId] = React.useState(0);
  const [available, setAvailable] = React.useState<bigint>(BigInt(0));
  const [creditCost, setCreditCost] = React.useState<bigint | null>(null);
  const [active, setActive] = React.useState(false);
  const [busy, setBusy] = React.useState(false);

  React.useEffect(() => {
    (async () => {
      if (!account) return;
      try {
        const p = await getPack(packId);
        setActive(Boolean(p.active));
        setCreditCost(BigInt(p.creditCost ?? 0));
        const bal = await userPackBalance(account, packId);
        setAvailable(BigInt(bal));
      } catch {
        setAvailable(BigInt(0));
        setActive(false);
        setCreditCost(null);
      }
    })();
  }, [account, packId]);

  if (!account) return <div className="text-gray-600">Connect your wallet to mint.</div>;

  const onMint = async () => {
    setBusy(true);
    try {
      const receipt = await mintFromPack(packId);
      alert('Minted! Tx confirmed at block ' + receipt.blockNumber);
    } catch (e: any) {
      alert(e.message ?? String(e));
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="space-y-6 max-w-md">
      <h1 className="text-2xl font-semibold">Mint from Pack</h1>
      <div className="space-y-3 rounded-lg border bg-white p-4">
        <label className="text-sm">Pack ID</label>
        <input type="number" value={packId} onChange={(e) => setPackId(parseInt(e.target.value || '0'))} className="w-full rounded border px-3 py-2" />
        <div className="text-sm text-gray-600">Available packs: {available.toString()}</div>
        <div className="text-sm text-gray-600">Credit cost: {creditCost !== null ? creditCost.toString() : 'N/A'}</div>
        <div className="text-sm">Status: {active ? 'Active' : 'Inactive'}</div>
        <button disabled={busy || !active || available === BigInt(0)} onClick={onMint} className="px-4 py-2 bg-indigo-600 text-white rounded hover:bg-indigo-700 disabled:opacity-50">
          Mint
        </button>
      </div>
    </div>
  );
}
