import { STAKE_ADDRESS } from '../config/contracts';
import stakeAbi from '../abi/stakeAbi.json';
import { getTronWeb } from './tron';

export async function getStakeRead(): Promise<{ tronWeb: any; contract: any }> {
  // This uses the injected TronWeb (read)
  // @ts-ignore
  const tronWeb = (window as any).tronWeb as any;
  if (!tronWeb) throw new Error('TronWeb not found');
  const contract = await tronWeb.contract((stakeAbi as any).abi).at(STAKE_ADDRESS);
  return { tronWeb, contract };
}

export async function getStakeWrite(): Promise<{ tronWeb: any; contract: any }> {
  const tronWeb = await getTronWeb();
  const contract = await tronWeb.contract((stakeAbi as any).abi).at(STAKE_ADDRESS);
  return { tronWeb, contract };
}

export async function fetchDashboard(address: string) {
  const { contract } = await getStakeRead();
  const [credits, totalStakedWei, userStake, totalSupply] = await Promise.all([
    contract.creditsOf(address).call(),
    contract.totalStakedWei().call(),
    contract.stakedBalanceWei(address).call(),
    contract.totalSupply().call(),
  ]);
  return {
    credits: toBigInt(credits),
    totalStakedWei: toBigInt(totalStakedWei),
    userStakedWei: toBigInt(userStake),
    totalSupply: toBigInt(totalSupply),
  };
}

export async function stakeEth(valueWei: bigint) {
  const { tronWeb, contract } = await getStakeWrite();
  const tx = await contract.stake().send({ callValue: safeNumber(valueWei) });
  return await waitForConfirmation(tronWeb, tx);
}

export async function withdrawStake(amountWei: bigint) {
  const { tronWeb, contract } = await getStakeWrite();
  const tx = await contract.withdrawStake(amountWei.toString()).send();
  return await waitForConfirmation(tronWeb, tx);
}

export async function getPack(packId: number) {
  const { contract } = await getStakeRead();
  const res = await contract.getPack(packId).call();
  // Normalize tuple or object to a consistent shape
  const priceWei = toBigInt((res && (res.priceWei ?? res[0])) ?? 0);
  const creditCost = toBigInt((res && (res.creditCost ?? res[1])) ?? 0);
  const active = Boolean(res && (typeof res.active !== 'undefined' ? res.active : res[2]));
  return { priceWei, creditCost, active };
}

export async function buyPack(packId: number, quantity: number, priceWeiPerPack: bigint) {
  const { tronWeb, contract } = await getStakeWrite();
  const total = priceWeiPerPack * BigInt(quantity);
  const tx = await contract.buyPack(packId, quantity).send({ callValue: safeNumber(total) });
  return await waitForConfirmation(tronWeb, tx);
}

export async function mintFromPack(packId: number) {
  const { tronWeb, contract } = await getStakeWrite();
  const tx = await contract.mintFromPack(packId).send();
  return await waitForConfirmation(tronWeb, tx);
}

export async function userPackBalance(address: string, packId: number) {
  const { contract } = await getStakeRead();
  const v = await contract.userPackBalance(address, packId).call();
  return toBigInt(v);
}

function toBigInt(v: any): bigint {
  if (typeof v === 'bigint') return v;
  if (typeof v === 'number') return BigInt(v);
  if (typeof v === 'string') return BigInt(v);
  if (v && typeof v._hex === 'string') return BigInt(v._hex);
  if (v && typeof v.toString === 'function') return BigInt(v.toString());
  throw new Error('Cannot convert to bigint');
}

function safeNumber(v: bigint): number {
  const n = Number(v);
  if (!Number.isFinite(n)) throw new Error('Value too large');
  return n;
}

async function waitForConfirmation(tronWeb: any, txId: string): Promise<any> {
  // Poll transaction info until confirmed
  for (;;) {
    const info = await tronWeb.trx.getTransactionInfo(txId);
    if (info && Object.keys(info).length) return info;
    await new Promise((r) => setTimeout(r, 1000));
  }
}
