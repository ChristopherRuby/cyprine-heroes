import React, { useState, useEffect } from 'react';
import { Hero, heroesApi } from '../../services/api';
import { useAuth } from '../../context/AuthContext';
import HeroForm from './HeroForm';

const HeroDashboard: React.FC = () => {
  const [heroes, setHeroes] = useState<Hero[]>([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [editingHero, setEditingHero] = useState<Hero | undefined>(undefined);
  const [error, setError] = useState('');
  const { logout } = useAuth();

  useEffect(() => {
    loadHeroes();
  }, []);

  const loadHeroes = async () => {
    try {
      setLoading(true);
      const response = await heroesApi.getAll();
      setHeroes(response.data);
    } catch (err) {
      console.error('Failed to load heroes:', err);
      setError('Impossible de charger les héros');
    } finally {
      setLoading(false);
    }
  };

  const handleCreateHero = () => {
    setEditingHero(undefined);
    setShowForm(true);
  };

  const handleEditHero = (hero: Hero) => {
    setEditingHero(hero);
    setShowForm(true);
  };

  const handleDeleteHero = async (hero: Hero) => {
    if (window.confirm(`Êtes-vous sûr de vouloir supprimer ${hero.nickname} ?`)) {
      try {
        await heroesApi.delete(hero.id);
        setHeroes(prev => prev.filter(h => h.id !== hero.id));
      } catch (err) {
        console.error('Failed to delete hero:', err);
        setError('Impossible de supprimer le héros');
      }
    }
  };

  const handleSaveHero = (savedHero: Hero) => {
    if (editingHero) {
      // Update existing hero
      setHeroes(prev => prev.map(h => h.id === savedHero.id ? savedHero : h));
    } else {
      // Add new hero
      setHeroes(prev => [...prev, savedHero]);
    }
    setShowForm(false);
    setEditingHero(undefined);
  };

  const handleCancelForm = () => {
    setShowForm(false);
    setEditingHero(undefined);
  };

  const handleLogout = () => {
    logout();
    window.location.href = '/admin';
  };

  if (showForm) {
    return (
      <HeroForm
        hero={editingHero}
        onSave={handleSaveHero}
        onCancel={handleCancelForm}
      />
    );
  }

  return (
    <div className="min-h-screen bg-cyprine-dark">
      {/* Header */}
      <header className="bg-gradient-to-r from-cyprine-darker to-cyprine-dark border-b border-gray-700 shadow-lg">
        <div className="container mx-auto px-6 py-6">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-3xl font-bold text-cyprine-cyan mb-1">Administration</h1>
              <p className="text-gray-300">Gérez les héros de la Cyprine</p>
            </div>
            <div className="flex items-center gap-4">
              <a
                href="/"
                className="px-4 py-2 text-gray-300 hover:text-cyprine-cyan transition-colors inline-flex items-center gap-2"
              >
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 19l-7-7m0 0l7-7m-7 7h18" />
                </svg>
                Accueil
              </a>
              <button
                onClick={handleLogout}
                className="px-4 py-2 bg-red-600 hover:bg-red-500 text-white font-medium rounded-lg transition-colors inline-flex items-center gap-2"
              >
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h7a3 3 0 013 3v1" />
                </svg>
                Déconnexion
              </button>
            </div>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="container mx-auto px-6 py-8">
        {/* Stats and Actions */}
        <div className="flex items-center justify-between mb-8">
          <div className="flex items-center gap-6">
            <div className="bg-gradient-to-br from-cyprine-darker to-cyprine-dark p-4 rounded-lg border border-gray-700">
              <div className="text-2xl font-bold text-cyprine-cyan">{heroes.length}</div>
              <div className="text-sm text-gray-300">Héros total</div>
            </div>
            <div className="bg-gradient-to-br from-cyprine-darker to-cyprine-dark p-4 rounded-lg border border-gray-700">
              <div className="text-2xl font-bold text-cyprine-orange">
                {heroes.reduce((sum, hero) => sum + Object.keys(hero.skills).length, 0)}
              </div>
              <div className="text-sm text-gray-300">Compétences total</div>
            </div>
          </div>
          
          <button
            onClick={handleCreateHero}
            className="px-6 py-3 bg-cyprine-cyan hover:bg-cyprine-cyan/80 text-cyprine-dark font-bold rounded-lg transition-colors inline-flex items-center gap-2 shadow-lg"
          >
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
            </svg>
            Nouveau héros
          </button>
        </div>

        {error && (
          <div className="bg-red-900/20 border border-red-500/50 rounded-lg p-4 mb-6">
            <p className="text-red-400">{error}</p>
          </div>
        )}

        {/* Heroes List */}
        {loading ? (
          <div className="text-center py-12">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-cyprine-cyan mx-auto mb-4"></div>
            <p className="text-gray-300">Chargement des héros...</p>
          </div>
        ) : heroes.length === 0 ? (
          <div className="text-center py-12 bg-gradient-to-br from-cyprine-darker to-cyprine-dark rounded-lg border-2 border-dashed border-gray-600">
            <svg className="w-16 h-16 text-gray-500 mx-auto mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
            </svg>
            <h3 className="text-xl font-bold text-gray-400 mb-2">Aucun héros</h3>
            <p className="text-gray-500 mb-4">Créez votre premier héros pour commencer !</p>
            <button
              onClick={handleCreateHero}
              className="px-6 py-2 bg-cyprine-cyan hover:bg-cyprine-cyan/80 text-cyprine-dark font-bold rounded-lg transition-colors"
            >
              Créer un héros
            </button>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {heroes.map((hero) => (
              <div
                key={hero.id}
                className="bg-gradient-to-br from-cyprine-darker to-cyprine-dark p-6 rounded-lg border border-gray-700 shadow-lg hover:shadow-xl transition-all duration-200"
              >
                {/* Hero Header */}
                <div className="flex items-center gap-4 mb-4">
                  <div className="w-16 h-16 rounded-full overflow-hidden bg-gray-800 border-2 border-cyprine-cyan/30">
                    {hero.profile_picture ? (
                      <img
                        src={`http://localhost:8000${hero.profile_picture}`}
                        alt={hero.nickname}
                        className="hero-img hero-img--sm"
                      />
                    ) : (
                      <div className="w-full h-full flex items-center justify-center text-xl font-bold text-cyprine-cyan">
                        {hero.nickname.charAt(0).toUpperCase()}
                      </div>
                    )}
                  </div>
                  <div className="flex-1">
                    <h3 className="text-lg font-bold text-cyprine-cyan">{hero.nickname}</h3>
                    <p className="text-gray-300 text-sm">{hero.firstname} {hero.lastname}</p>
                  </div>
                </div>

                {/* Description preview */}
                <p className="text-gray-400 text-sm mb-4 line-clamp-3">
                  {hero.description}
                </p>

                {/* Skills count */}
                <div className="flex items-center justify-between mb-4">
                  <span className="text-xs text-gray-500">
                    {Object.keys(hero.skills).length} compétence(s)
                  </span>
                  <span className="text-xs text-gray-500">
                    Créé le {new Date(hero.created_at).toLocaleDateString('fr-FR')}
                  </span>
                </div>

                {/* Actions */}
                <div className="flex gap-2">
                  <button
                    onClick={() => handleEditHero(hero)}
                    className="flex-1 py-2 px-3 bg-cyprine-purple hover:bg-cyprine-purple/80 text-white text-sm font-medium rounded transition-colors inline-flex items-center justify-center gap-1"
                  >
                    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                    </svg>
                    Modifier
                  </button>
                  <button
                    onClick={() => handleDeleteHero(hero)}
                    className="py-2 px-3 bg-red-600 hover:bg-red-500 text-white text-sm font-medium rounded transition-colors inline-flex items-center justify-center"
                  >
                    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                    </svg>
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </main>
    </div>
  );
};

export default HeroDashboard;