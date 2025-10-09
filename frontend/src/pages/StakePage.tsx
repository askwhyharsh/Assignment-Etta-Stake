import React from 'react';
import { stakeEth, withdrawStake } from '../lib/stakeContract';

type Props = { account: string | null };

export default function StakePage({ account }: Props) {
  const [amountEth, setAmountEth] = React.useState('');
  const [withdrawEth, setWithdrawEth] = React.useState('');
  const [busy, setBusy] = React.useState(false);
  const baseUnit = 1e6; // for tron it's 1e6 for eth it was 1e18
  if (!account) return <div className="text-gray-600">Connect your wallet to stake.</div>;

  const onStake = async () => {
    if (!amountEth) return;
    setBusy(true);
    try {
      const wei = BigInt(Math.floor(parseFloat(amountEth) * baseUnit));
      await stakeEth(wei);
      alert('Staked successfully');
    } catch (e: any) {
      alert(e.message ?? String(e));
    } finally {
      setBusy(false);
    }
  };

  const onWithdraw = async () => {
    if (!withdrawEth) return;
    setBusy(true);
    try {
      const wei = BigInt(Math.floor(parseFloat(withdrawEth) * baseUnit));
      await withdrawStake(wei);
      alert('Withdrawn successfully');
    } catch (e: any) {
      alert(e.message ?? String(e));
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="space-y-6 max-w-md">
      <h1 className="text-2xl font-semibold">Stake / Unstake</h1>
      <div>you get 1000 credits for 1 TRX</div>
      <div className="space-y-3 rounded-lg border bg-white p-4">
        <div className="text-sm font-medium">Stake TRX</div>
        <input
          type="number"
          min="0"
          step="0.0001"
          placeholder="Amount in TRX"
          value={amountEth}
          onChange={(e) => setAmountEth(e.target.value)}
          className="w-full rounded border px-3 py-2"
        />
        <button disabled={busy} onClick={onStake} className="px-4 py-2 bg-indigo-600 text-white rounded hover:bg-indigo-700 disabled:opacity-50">
          Stake
        </button>
      </div>

      <div className="space-y-3 rounded-lg border bg-white p-4">
        <div className="text-sm font-medium">Unstake TRX</div>
        <input
          type="number"
          min="0"
          step="0.0001"
          placeholder="Amount in TRX"
          value={withdrawEth}
          onChange={(e) => setWithdrawEth(e.target.value)}
          className="w-full rounded border px-3 py-2"
        />
        <button disabled={busy} onClick={onWithdraw} className="px-4 py-2 bg-gray-700 text-white rounded hover:bg-gray-800 disabled:opacity-50">
          Unstake
        </button>
      </div>
    </div>
  );
}
