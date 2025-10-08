import React from 'react';
import { BrowserRouter, Routes, Route, Link, Navigate } from 'react-router-dom';
import ConnectWallet from './components/ConnectWallet';
import Dashboard from './pages/Dashboard';
import StakePage from './pages/StakePage';
import PackPage from './pages/PackPage';
import MintPage from './pages/MintPage';

function App() {
  const [account, setAccount] = React.useState<string | null>(null);

  return (
    <BrowserRouter>
      <div className="min-h-screen bg-gray-50">
        <header className="border-b bg-white">
          <div className="max-w-6xl mx-auto px-4 py-3 flex items-center justify-between">
            <nav className="flex items-center gap-4 text-sm">
              <Link className="font-semibold" to="/">Stake dApp</Link>
              <Link to="/stake" className="hover:underline">Stake</Link>
              <Link to="/packs" className="hover:underline">Packs</Link>
              <Link to="/mint" className="hover:underline">Mint</Link>
            </nav>
            <ConnectWallet account={account} setAccount={setAccount} />
          </div>
        </header>
        <main className="max-w-6xl mx-auto px-4 py-6">
          <Routes>
            <Route path="/" element={<Dashboard account={account} />} />
            <Route path="/stake" element={<StakePage account={account} />} />
            <Route path="/packs" element={<PackPage account={account} />} />
            <Route path="/mint" element={<MintPage account={account} />} />
            <Route path="*" element={<Navigate to="/" replace />} />
          </Routes>
        </main>
      </div>
    </BrowserRouter>
  );
}

export default App;
