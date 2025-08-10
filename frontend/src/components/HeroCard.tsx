import React from 'react';
import { Hero } from '../services/api';

interface HeroCardProps {
  hero: Hero;
  isSelected: boolean;
  onClick: () => void;
  onDragStart?: (e: React.DragEvent, hero: Hero) => void;
}

const HeroCard: React.FC<HeroCardProps> = ({ hero, isSelected, onClick, onDragStart }) => {
  const handleDragStart = (e: React.DragEvent) => {
    if (onDragStart) {
      onDragStart(e, hero);
    }
  };

  return (
    <div
      className={`
  relative group cursor-pointer hero-card ${isSelected ? 'is-selected' : ''}
        bg-gradient-to-b from-cyprine-darker to-cyprine-dark
  border-2 border-gray-700
        rounded-lg p-4 min-w-[200px] max-w-[200px]
      `}
      onClick={onClick}
      draggable={!!onDragStart}
      onDragStart={handleDragStart}
    >
      {/* Profile Picture */}
      <div className="relative mb-3 overflow-hidden rounded-lg aspect-square bg-gray-800">
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
        
        {/* Glow effect */}
        {isSelected && (
          <div className="absolute inset-0 bg-cyprine-cyan/20 animate-pulse" />
        )}
      </div>

      {/* Hero Info */}
      <div className="text-center">
        <h3 className="text-cyprine-cyan font-bold text-lg mb-1 truncate">
          {hero.nickname}
        </h3>
        <p className="text-gray-300 text-sm truncate">
          {hero.firstname} {hero.lastname}
        </p>
      </div>

      {/* Hover overlay */}
      <div className="absolute inset-0 bg-cyprine-cyan/10 opacity-0 group-hover:opacity-100 transition-opacity duration-300 rounded-lg" />
      
      {/* Selection indicator */}
      {isSelected && (
        <div className="absolute -top-2 -right-2 w-6 h-6 bg-cyprine-cyan rounded-full flex items-center justify-center">
          <div className="w-3 h-3 bg-white rounded-full" />
        </div>
      )}
    </div>
  );
};

export default HeroCard;