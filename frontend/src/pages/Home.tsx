import React, { useState, useEffect } from 'react';
import { Hero, heroesApi } from '../services/api';
import HeroGallery from '../components/HeroGallery';
import HeroDetails from '../components/HeroDetails';
import TeamComposition from '../components/TeamComposition';

const Home: React.FC = () => {
  const [heroes, setHeroes] = useState<Hero[]>([]);
  const [selectedHero, setSelectedHero] = useState<Hero | null>(null);
  const [team, setTeam] = useState<(Hero | null)[]>([null, null, null]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [draggedHero, setDraggedHero] = useState<Hero | null>(null);

  useEffect(() => {
    loadHeroes();
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const loadHeroes = async () => {
    try {
      setLoading(true);
      const response = await heroesApi.getAll();
      setHeroes(response.data);
      // Select first hero by default if available
      if (response.data.length > 0 && !selectedHero) {
        setSelectedHero(response.data[0]);
      }
    } catch (err) {
      console.error('Failed to load heroes:', err);
      setError('Impossible de charger les héros. Vérifiez que le serveur est démarré.');
    } finally {
      setLoading(false);
    }
  };

  const handleHeroSelect = (hero: Hero) => {
    setSelectedHero(hero);
  };

  const handleDragStart = (e: React.DragEvent, hero: Hero) => {
    setDraggedHero(hero);
    e.dataTransfer.effectAllowed = 'copy';
  };

  const handleDragOver = (e: React.DragEvent) => {
    e.preventDefault();
    e.dataTransfer.dropEffect = 'copy';
  };

  const handleDrop = (e: React.DragEvent, slotIndex: number) => {
    e.preventDefault();
    if (draggedHero && !team.includes(draggedHero)) {
      const newTeam = [...team];
      newTeam[slotIndex] = draggedHero;
      setTeam(newTeam);
    }
    setDraggedHero(null);
  };

  const handleRemoveFromTeam = (slotIndex: number) => {
    const newTeam = [...team];
    newTeam[slotIndex] = null;
    setTeam(newTeam);
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-cyprine-dark flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-16 w-16 border-b-2 border-cyprine-cyan mx-auto mb-4"></div>
          <p className="text-cyprine-cyan text-lg">Chargement des héros...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="min-h-screen bg-cyprine-dark flex items-center justify-center">
        <div className="text-center bg-red-900/20 border border-red-500/50 rounded-lg p-8 max-w-md">
          <svg className="w-16 h-16 text-red-500 mx-auto mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L4.082 16.5c-.77.833.192 2.5 1.732 2.5z" />
          </svg>
          <h2 className="text-xl font-bold text-red-500 mb-2">Erreur de connexion</h2>
          <p className="text-gray-300 mb-4">{error}</p>
          <button
            onClick={loadHeroes}
            className="bg-cyprine-cyan hover:bg-cyprine-cyan/80 text-cyprine-dark font-bold py-2 px-4 rounded transition-colors"
          >
            Réessayer
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-cyprine-dark">
      {/* Header */}
      <header className="bg-gradient-to-r from-cyprine-darker to-cyprine-dark border-b border-gray-700 shadow-lg">
        <div className="container mx-auto px-6 py-8">
          {/* Admin link - top right, subtle link */}
          <div className="flex justify-end mb-4">
            <a
              href="/admin"
              className="text-gray-400 hover:text-cyprine-cyan text-sm transition-colors underline-offset-2 hover:underline"
            >
              Administration
            </a>
          </div>
          
          <h1 className="text-5xl font-bold text-center mb-2" style={{
            background: 'linear-gradient(to right, var(--cyprine-cyan), var(--cyprine-purple))',
            WebkitBackgroundClip: 'text',
            WebkitTextFillColor: 'transparent',
            backgroundClip: 'text'
          }}>
            Les héros de la Cyprine
          </h1>
          <p className="text-xl text-center text-gray-300">
            Assemble et viens boire une cyprinade ! 🍺
          </p>
        </div>
      </header>

      {/* Main Content */}
      <main className="container mx-auto px-6 py-8">
        <div className="space-y-8">
          {/* Team Composition - moved above Gallery */}
          <section>
            <TeamComposition
              team={team}
              onDropHero={(index, hero) => {
                const newTeam = [...team];
                newTeam[index] = hero;
                setTeam(newTeam);
              }}
              onRemoveHero={handleRemoveFromTeam}
              onDragOver={handleDragOver}
              onDrop={handleDrop}
            />
          </section>

          {/* Hero Gallery */}
          <section>
            <HeroGallery
              heroes={heroes}
              selectedHero={selectedHero}
              onHeroSelect={handleHeroSelect}
              onDragStart={handleDragStart}
            />
          </section>

          {/* Hero Details */}
          <section>
            <h2 className="text-2xl font-bold text-cyprine-cyan mb-6 text-center">
              Détails du Héros
            </h2>
            <HeroDetails hero={selectedHero} />
          </section>

        </div>
      </main>

      {/* Footer */}
      <footer className="bg-cyprine-darker border-t border-gray-700 mt-16">
        <div className="container mx-auto px-6 py-6 text-center text-gray-400">
          <p>&copy; 2024 Les héros de la Cyprine - Tous droits réservés</p>
        </div>
      </footer>
    </div>
  );
};

export default Home;