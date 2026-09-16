'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';

export default function Dashboard() {
  const [settings, setSettings] = useState(null);
  const [loading, setLoading] = useState(true);
  const [updating, setUpdating] = useState(false);

  const router = useRouter();

  useEffect(() => {
    const isLoggedIn = localStorage.getItem('isLoggedIn');
    if (isLoggedIn !== 'true') {
      router.push('/login');
    } else {
      fetchSettings();
    }
  }, [router]);

  const fetchSettings = async () => {
    try {
      const res = await fetch('/api/settings');
      const data = await res.json();
      setSettings(data);
      setLoading(false);
    } catch (err) {
      console.error(err);
    }
  };

  const switchProvider = async (providerId) => {
    setUpdating(true);
    try {
      const res = await fetch('/api/settings', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ active_provider: providerId })
      });
      const data = await res.json();
      setSettings(data);
    } catch (err) {
      console.error(err);
    } finally {
      setUpdating(false);
    }
  };

  if (loading) return <div className="loading">Initializing Cosmic Hub...</div>;

  return (
    <main style={{ padding: '4rem 2rem' }}>
      <header style={{ textAlign: 'center', marginBottom: '4rem', position: 'relative' }}>
        <button 
          onClick={() => {
            localStorage.removeItem('isLoggedIn');
            router.push('/login');
          }}
          style={{ 
            position: 'absolute', 
            right: 0, 
            top: 0, 
            background: 'rgba(255,255,255,0.05)', 
            border: '1px solid var(--border)', 
            color: 'white', 
            padding: '0.5rem 1rem', 
            borderRadius: '8px', 
            cursor: 'pointer' 
          }}
        >
          Logout
        </button>
        <h1>AI Model Maestro</h1>
        <p style={{ opacity: 0.7, fontSize: '1.2rem' }}>Centralized neural orchestration for all your projects.</p>
      </header>

      <div className="grid-layout">
        {Object.entries(settings.providers).map(([id, provider]) => (
          <div key={id} className={`glass-card ${settings.active_provider === id ? 'active-border' : ''}`}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem' }}>
              <h2 style={{ fontSize: '1.5rem', fontWeight: '600' }}>{provider.name}</h2>
              {settings.active_provider === id && <span className="badge-active">ACTIVE</span>}
            </div>
            
            <p style={{ opacity: 0.6, marginBottom: '2rem' }}>
              Base Model: <code style={{ background: 'rgba(255,255,255,0.1)', padding: '2px 6px', borderRadius: '4px' }}>{provider.model}</code>
            </p>

            <button 
              className="btn-premium" 
              style={{ width: '100%', opacity: settings.active_provider === id ? 0.5 : 1 }}
              onClick={() => switchProvider(id)}
              disabled={updating || settings.active_provider === id}
            >
              {updating ? 'Orbiting...' : settings.active_provider === id ? 'Currently Serving' : 'Switch to this Model'}
            </button>
          </div>
        ))}
      </div>

      <style jsx>{`
        .active-border {
          border-color: var(--accent) !important;
          background: rgba(124, 58, 237, 0.05);
        }
        .loading {
          height: 100vh;
          display: flex;
          align-items: center;
          justify-content: center;
          font-size: 2rem;
          font-weight: 800;
          letter-spacing: -1px;
        }
      `}</style>
    </main>
  );
}
