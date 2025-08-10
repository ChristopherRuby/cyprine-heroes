import React, { useState } from 'react';
import { useAuth } from '../context/AuthContext';
import LoginForm from '../components/Admin/LoginForm';
import HeroDashboard from '../components/Admin/HeroDashboard';

const Admin: React.FC = () => {
  const { isAuthenticated, loading } = useAuth();
  const [loginSuccess, setLoginSuccess] = useState(false);

  // Show loading while checking auth status
  if (loading) {
    return (
      <div className="min-h-screen bg-cyprine-dark flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-16 w-16 border-b-2 border-cyprine-cyan mx-auto mb-4"></div>
          <p className="text-cyprine-cyan text-lg">Vérification de l'authentification...</p>
        </div>
      </div>
    );
  }

  // Show dashboard if authenticated
  if (isAuthenticated || loginSuccess) {
    return <HeroDashboard />;
  }

  // Show login form if not authenticated
  return <LoginForm onLoginSuccess={() => setLoginSuccess(true)} />;
};

export default Admin;