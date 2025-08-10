import React from 'react';
import { Hero } from '../services/api';

interface HeroDetailsProps {
  hero: Hero | null;
}

const HeroDetails: React.FC<HeroDetailsProps> = ({ hero }) => {
  if (!hero) {
    return (
      <div className="bg-cyprine-darker/30 rounded-lg p-8 text-center border-2 border-dashed border-gray-600">
        <div className="text-gray-400 text-lg">
          <svg className="w-20 h-20 mx-auto mb-4 text-gray-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
          </svg>
          Sélectionnez un héros pour voir ses détails
        </div>
      </div>
    );
  }

  const renderStars = (rating: number) => {
    return Array.from({ length: 5 }, (_, index) => (
      <svg
        key={index}
        className={`w-5 h-5 ${
          index < rating ? 'text-cyprine-orange' : 'text-gray-600'
        }`}
        fill="currentColor"
        viewBox="0 0 20 20"
      >
        <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
      </svg>
    ));
  };

  return (
    <div className="bg-gradient-to-br from-cyprine-darker to-cyprine-dark rounded-lg p-8 border border-gray-700 shadow-2xl">
      {/* Hero Header */}
      <div className="flex items-center gap-6 mb-6">
        {/* Profile Picture */}
        <div className="relative">
          <div className="w-32 h-32 rounded-full overflow-hidden bg-gray-800 border-4 border-cyprine-cyan shadow-lg shadow-cyprine-cyan/30">
            {hero.profile_picture ? (
              <img
                src={`http://localhost:8000${hero.profile_picture}`}
                alt={hero.nickname}
                className="hero-img hero-img--md"
              />
            ) : (
              <div className="w-full h-full flex items-center justify-center text-4xl font-bold text-cyprine-cyan">
                {hero.nickname.charAt(0).toUpperCase()}
              </div>
            )}
          </div>
          {/* Glow effect */}
          <div className="absolute inset-0 rounded-full bg-cyprine-cyan/20 animate-pulse" />
        </div>

        {/* Hero Info */}
        <div className="flex-1">
          <h1 className="text-4xl font-bold text-cyprine-cyan mb-2 animate-fade-in">
            {hero.nickname}
          </h1>
          <p className="text-xl text-gray-300 mb-1">
            {hero.firstname} {hero.lastname}
          </p>
          <div className="text-sm text-gray-400">
            Membre depuis {new Date(hero.created_at).toLocaleDateString('fr-FR')}
          </div>
        </div>
      </div>

      {/* Description */}
      <div className="mb-8">
        <h3 className="text-xl font-bold text-cyprine-cyan mb-3">Description</h3>
        <p className="text-gray-300 leading-relaxed bg-cyprine-darker/50 p-4 rounded-lg border border-gray-600">
          {hero.description}
        </p>
      </div>

      {/* Skills */}
      <div>
        <h3 className="text-xl font-bold text-cyprine-cyan mb-4">Compétences</h3>
        {Object.keys(hero.skills).length === 0 ? (
          <p className="text-gray-400 italic">Aucune compétence définie</p>
        ) : (
          <div className="space-y-3">
            {Object.entries(hero.skills).map(([skill, rating]) => (
              <div key={skill} className="flex items-center justify-between p-3 bg-cyprine-darker/50 rounded-lg border border-gray-600">
                <span className="text-white font-medium capitalize">
                  {skill.replace('_', ' ')}
                </span>
                <div className="flex items-center gap-2">
                  <div className="flex gap-1">
                    {renderStars(Number(rating))}
                  </div>
                  <span className="text-cyprine-cyan font-bold min-w-[2ch]">
                    {rating}/5
                  </span>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};

export default HeroDetails;