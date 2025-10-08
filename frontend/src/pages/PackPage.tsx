import React from 'react';
import { buyPack, getPack } from '../lib/stakeContract';

type Props = { account: string | null };

export default function PackPage({ account }: Props) {
  const [packId, setPackId] = React.useState(0);
  const [quantity, setQuantity] = React.useState(1);
  const [pricePerPack, setPricePerPack] = React.useState<bigint | null>(null);
  const [active, setActive] = React.useState<boolean>(false);
  const [busy, setBusy] = React.useState(false);

  React.useEffect(() => {
    (async () => {
      try {
        const p = await getPack(packId);
        setPricePerPack(BigInt(p.priceWei ?? 0));
        setActive(Boolean(p.active));
      } catch {
        setPricePerPack(null);
        setActive(false);
      }
    })();
  }, [packId]);

  if (!account) return <div className="text-gray-600">Connect your wallet to purchase packs.</div>;

  const onBuy = async () => {
    if (!pricePerPack || !active) return alert('Pack not available');
    setBusy(true);
    try {
      await buyPack(packId, quantity, pricePerPack);
      alert('Purchased');
    } catch (e: any) {
      alert(e.message ?? String(e));
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="space-y-6 max-w-md">
      <h1 className="text-2xl font-semibold">Buy Packs</h1>

      <div className="space-y-3 rounded-lg border bg-white p-4">
        <label className="text-sm">Pack ID</label>
        <input type="number" value={packId} onChange={(e) => setPackId(parseInt(e.target.value || '0'))} className="w-full rounded border px-3 py-2" />
        <label className="text-sm">Quantity</label>
        <input type="number" min={1} value={quantity} onChange={(e) => setQuantity(parseInt(e.target.value || '1'))} className="w-full rounded border px-3 py-2" />
        <div className="text-sm text-gray-600">Price per pack: {pricePerPack ? formatEth(pricePerPack) + ' ETH' : 'N/A'}</div>
        <div className="text-sm">Status: {active ? 'Active' : 'Inactive'}</div>
        <button disabled={busy || !active || !pricePerPack} onClick={onBuy} className="px-4 py-2 bg-indigo-600 text-white rounded hover:bg-indigo-700 disabled:opacity-50">
          Buy
        </button>
      </div>
    </div>
  );
}

function formatEth(wei: bigint): string {
  const eth = Number(wei) / 1e18;
  return eth.toLocaleString(undefined, { maximumFractionDigits: 6 });
}
