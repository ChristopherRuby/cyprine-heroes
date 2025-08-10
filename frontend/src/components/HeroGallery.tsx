import React from 'react';
import { Hero } from '../services/api';
import HeroCard from './HeroCard';

interface HeroGalleryProps {
  heroes: Hero[];
  selectedHero: Hero | null;
  onHeroSelect: (hero: Hero) => void;
  onDragStart?: (e: React.DragEvent, hero: Hero) => void;
}

const HeroGallery: React.FC<HeroGalleryProps> = ({
  heroes,
  selectedHero,
  onHeroSelect,
  onDragStart,
}) => {
  if (heroes.length === 0) {
    return (
      <div className="w-full bg-cyprine-darker/50 rounded-lg p-8 text-center border-2 border-dashed border-gray-600">
        <div className="text-gray-400 text-lg mb-4">
          <svg className="w-16 h-16 mx-auto mb-4 text-gray-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
          </svg>
          Aucun héros n'est encore disponible
        </div>
        <p className="text-gray-500">
          Utilisez l'interface d'administration pour ajouter vos premiers héros !
        </p>
      </div>
    );
  }

  return (
    <div className="w-full">
      <h2 className="text-2xl font-bold text-cyprine-cyan mb-6 text-center">
        Galerie des Héros
      </h2>
      
      {/* Wrapping gallery grid */}
      <div className="hero-grid px-4">
        {heroes.map((hero) => (
          <HeroCard
            key={hero.id}
            hero={hero}
            isSelected={selectedHero?.id === hero.id}
            onClick={() => onHeroSelect(hero)}
            onDragStart={onDragStart}
          />
        ))}
      </div>
    </div>
  );
};

export default HeroGallery;