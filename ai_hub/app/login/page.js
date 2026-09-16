'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';

export default function LoginPage() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const router = useRouter();

  useEffect(() => {
    const isLoggedIn = localStorage.getItem('isLoggedIn');
    if (isLoggedIn === 'true') {
      router.push('/');
    }
  }, [router]);

  const handleLogin = (e) => {
    e.preventDefault();
    setIsLoading(true);
    setError('');

    const activeId = 'anandyadav21219@gmail.com';

    if (email === activeId && password === activeId) {
      setTimeout(() => {
        localStorage.setItem('isLoggedIn', 'true');
        localStorage.setItem('userEmail', email);
        router.push('/');
      }, 1500);
    } else {
      setTimeout(() => {
        setError('Unauthorized Access: This terminal is restricted.');
        setIsLoading(false);
      }, 1000);
    }
  };

  return (
    <div className="login-wrapper">
      <div className="bg-image"></div>
      <div className="overlay"></div>
      
      <div className="login-card">
        <div className="logo-section">
          <div className="orb"></div>
          <h1>Model Maestro</h1>
          <p>AUTHORIZED PERSONNEL ONLY</p>
        </div>

        <form onSubmit={handleLogin} className="login-form">
          <div className="input-field">
            <input 
              type="email" 
              value={email} 
              onChange={(e) => setEmail(e.target.value)}
              placeholder="System ID"
              required
            />
            <div className="line"></div>
          </div>

          <div className="input-field">
            <input 
              type="password" 
              value={password} 
              onChange={(e) => setPassword(e.target.value)}
              placeholder="Access Key"
              required
            />
            <div className="line"></div>
          </div>

          {error && <div className="error-msg">{error}</div>}

          <button type="submit" className="login-btn" disabled={isLoading}>
            {isLoading ? <span className="loader"></span> : 'INITIALIZE SESSION'}
          </button>
        </form>
      </div>

      <style jsx>{`
        .login-wrapper {
          height: 100vh;
          width: 100vw;
          display: flex;
          align-items: center;
          justify-content: center;
          overflow: hidden;
          position: relative;
          color: white;
        }

        .bg-image {
          position: absolute;
          top: 0;
          left: 0;
          right: 0;
          bottom: 0;
          background: url('/premium_login_background_1775812421960.png');
          background-size: cover;
          background-position: center;
          filter: brightness(0.4) scale(1.1);
          animation: slowPulse 20s infinite alternate;
          z-index: -2;
        }

        .overlay {
          position: absolute;
          inset: 0;
          background: radial-gradient(circle at center, transparent 0%, rgba(0,0,0,0.8) 100%);
          z-index: -1;
        }

        .login-card {
          width: 100%;
          max-width: 400px;
          padding: 3.5rem;
          background: rgba(255, 255, 255, 0.03);
          backdrop-filter: blur(20px);
          -webkit-backdrop-filter: blur(20px);
          border: 1px solid rgba(255, 255, 255, 0.1);
          border-radius: 32px;
          box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.5);
          text-align: center;
          animation: slideUp 0.8s cubic-bezier(0.16, 1, 0.3, 1);
        }

        .logo-section h1 {
          font-size: 2.2rem;
          font-weight: 800;
          letter-spacing: -1px;
          margin-bottom: 0.2rem;
          background: linear-gradient(to right, #fff, #a78bfa);
          -webkit-background-clip: text;
          background-clip: text;
          -webkit-text-fill-color: transparent;
        }

        .logo-section p {
          font-size: 0.75rem;
          letter-spacing: 3px;
          font-weight: 600;
          opacity: 0.5;
          margin-bottom: 3rem;
        }

        .orb {
          width: 60px;
          height: 60px;
          background: var(--accent);
          border-radius: 50%;
          margin: 0 auto 1.5rem;
          filter: blur(20px);
          opacity: 0.6;
          animation: orbGlow 4s infinite ease-in-out;
        }

        .input-field {
          position: relative;
          margin-bottom: 2rem;
        }

        .input-field input {
          width: 100%;
          background: transparent;
          border: none;
          padding: 0.8rem 0;
          color: white;
          font-size: 1rem;
          outline: none;
        }

        .input-field .line {
          height: 1px;
          width: 100%;
          background: rgba(255,255,255,0.2);
          transition: background 0.3s;
        }

        .input-field input:focus + .line {
          background: var(--accent);
          box-shadow: 0 0 10px var(--accent-glow);
        }

        .login-btn {
          width: 100%;
          padding: 1.2rem;
          background: white;
          color: black;
          border: none;
          border-radius: 12px;
          font-weight: 800;
          font-size: 0.9rem;
          letter-spacing: 1px;
          cursor: pointer;
          transition: all 0.3s;
          margin-top: 1rem;
        }

        .login-btn:hover {
          background: var(--accent);
          color: white;
          box-shadow: 0 0 20px var(--accent-glow);
          transform: translateY(-2px);
        }

        .error-msg {
          color: #ff4d4d;
          font-size: 0.8rem;
          margin-bottom: 1.5rem;
          background: rgba(255, 77, 77, 0.1);
          padding: 0.75rem;
          border-radius: 8px;
          border: 1px solid rgba(255, 77, 77, 0.2);
        }

        @keyframes slowPulse {
          from { transform: scale(1); }
          to { transform: scale(1.1); }
        }

        @keyframes slideUp {
          from { opacity: 0; transform: translateY(30px); }
          to { opacity: 1; transform: translateY(0); }
        }

        @keyframes orbGlow {
          0%, 100% { transform: scale(1); filter: blur(20px); }
          50% { transform: scale(1.5); filter: blur(30px); }
        }

        .loader {
          width: 20px;
          height: 20px;
          border: 2px solid rgba(0,0,0,0.1);
          border-top-color: currentColor;
          border-radius: 50%;
          display: inline-block;
          animation: spin 1s linear infinite;
        }

        @keyframes spin {
          to { transform: rotate(360deg); }
        }
      `}</style>
    </div>
  );
}
