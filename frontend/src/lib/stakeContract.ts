import { ethers } from 'ethers';
import { STAKE_ADDRESS } from '../config/contracts';
import stakeAbi from '../abi/stakeAbi.json';
import { getProvider, getSigner } from './eth';

export function getStakeRead(): ethers.Contract {
  const provider = getProvider();
  return new ethers.Contract(STAKE_ADDRESS, (stakeAbi as any).abi, provider);
}

export async function getStakeWrite(): Promise<ethers.Contract> {
  const signer = await getSigner();
  return new ethers.Contract(STAKE_ADDRESS, (stakeAbi as any).abi, signer);
}

export async function fetchDashboard(address: string) {
  const c = getStakeRead();
  const [credits, totalStakedWei, userStake, totalSupply] = await Promise.all([
    c.creditsOf(address),
    c.totalStakedWei(),
    c.stakedBalanceWei(address),
    c.totalSupply(),
  ]);
  return {
    credits: credits as bigint,
    totalStakedWei: totalStakedWei as bigint,
    userStakedWei: userStake as bigint,
    totalSupply: totalSupply as bigint,
  };
}

export async function stakeEth(valueWei: bigint) {
  const c = await getStakeWrite();
  const tx = await c.stake({ value: valueWei });
  return await tx.wait();
}

export async function withdrawStake(amountWei: bigint) {
  const c = await getStakeWrite();
  const tx = await c.withdrawStake(amountWei);
  return await tx.wait();
}

export async function getPack(packId: number) {
  const c = getStakeRead();
  return await c.packs(packId);
}

export async function buyPack(packId: number, quantity: number, priceWeiPerPack: bigint) {
  const c = await getStakeWrite();
  const total = priceWeiPerPack * BigInt(quantity);
  const tx = await c.buyPack(packId, quantity, { value: total });
  return await tx.wait();
}

export async function mintFromPack(packId: number) {
  const c = await getStakeWrite();
  const tx = await c.mintFromPack(packId);
  return await tx.wait();
}

export async function userPackBalance(address: string, packId: number) {
  const c = getStakeRead();
  return await c.userPackBalance(address, packId);
}
