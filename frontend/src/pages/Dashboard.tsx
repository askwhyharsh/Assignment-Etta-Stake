import React from 'react';
import { fetchDashboard, userPackBalance, getPack } from '../lib/stakeContract';

type Props = { account: string | null };

export default function Dashboard({ account }: Props) {
  const [loading, setLoading] = React.useState(false);
  const [data, setData] = React.useState<{
    credits: bigint;
    totalStakedWei: bigint;
    userStakedWei: bigint;
    totalSupply: bigint;
  } | null>(null);
  const [packsOwned, setPacksOwned] = React.useState<Record<number, bigint>>({});

  const load = React.useCallback(async () => {
    if (!account) return;
    setLoading(true);
    try {
      const d = await fetchDashboard(account);
      setData(d);
      // Sample: show first few pack IDs (0..2) if configured
      const ids = [0,1,2];
      const results: Record<number, bigint> = {};
      for (const id of ids) {
        try {
          const p = await getPack(id);
          if (p && p.active) {
            const bal = await userPackBalance(account, id);
            results[id] = BigInt(bal);
          }
        } catch {}
      }
      setPacksOwned(results);
    } finally {
      setLoading(false);
    }
  }, [account]);

  React.useEffect(() => { load(); }, [load]);

  if (!account) return <div className="text-gray-600">Connect your wallet to view dashboard.</div>;

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-semibold">Dashboard</h1>
      {loading && <div>Loading...</div>}
      {data && (
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <Card title="Your Credits" value={formatNumber(data.credits)} />
          <Card title="Your Staked (TRX)" value={formatEth(data.userStakedWei)} />
          <Card title="Total Staked (TRX)" value={formatEth(data.totalStakedWei)} />
          <Card title="Total NFTs" value={formatNumber(data.totalSupply)} />
        </div>
      )}
      <div>
        <h2 className="text-lg font-semibold mb-2">Packs Owned</h2>
        {Object.keys(packsOwned).length === 0 ? (
          <div className="text-sm text-gray-600">No active packs detected yet.</div>
        ) : (
          <ul className="list-disc pl-5 space-y-1">
            {Object.entries(packsOwned).map(([id, qty]) => (
              <li key={id}>Pack {id}: {formatNumber(qty)}</li>
            ))}
          </ul>
        )}
      </div>
    </div>
  );
}

function Card({ title, value }: { title: string; value: string }) {
  return (
    <div className="rounded-lg border bg-white p-4">
      <div className="text-sm text-gray-500">{title}</div>
      <div className="text-xl font-semibold">{value}</div>
    </div>
  );
}

function formatEth(wei: bigint): string {
  const eth = Number(wei) / 1e6;
  return eth.toLocaleString(undefined, { maximumFractionDigits: 6 });
}

function formatNumber(n: bigint): string {
  return Number(n).toLocaleString();
}
