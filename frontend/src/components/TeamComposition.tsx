import React from 'react';
import { Hero } from '../services/api';

interface TeamCompositionProps {
  team: (Hero | null)[];
  onDropHero: (index: number, hero: Hero) => void;
  onRemoveHero: (index: number) => void;
  onDragOver: (e: React.DragEvent) => void;
  onDrop: (e: React.DragEvent, index: number) => void;
}

const TeamComposition: React.FC<TeamCompositionProps> = ({
  team,
  onRemoveHero,
  onDragOver,
  onDrop,
}) => {
  const TeamSlot: React.FC<{ hero: Hero | null; index: number }> = ({ hero, index }) => {
    const handleDrop = (e: React.DragEvent) => {
      onDrop(e, index);
    };

    return (
      <div
        className={`
          relative h-48 w-36 rounded-lg border-2 border-dashed transition-all duration-300
          ${hero 
            ? 'border-cyprine-cyan bg-gradient-to-b from-cyprine-darker to-cyprine-dark shadow-lg shadow-cyprine-cyan/30' 
            : 'border-gray-600 bg-cyprine-darker/30 hover:border-cyprine-cyan/50 hover:bg-cyprine-darker/50'
          }
        `}
        onDragOver={onDragOver}
        onDrop={handleDrop}
      >
        {hero ? (
          <>
            {/* Hero in slot */}
            <div className="p-3 h-full flex flex-col">
              {/* Profile picture */}
              <div className="w-20 h-20 mx-auto mb-2 rounded-full overflow-hidden bg-gray-800 border-2 border-cyprine-cyan">
                {hero.profile_picture ? (
                  <img
                    src={`http://localhost:8000${hero.profile_picture}`}
                    alt={hero.nickname}
                    className="hero-img hero-img--xs"
                  />
                ) : (
                  <div className="w-full h-full flex items-center justify-center text-xl font-bold text-cyprine-cyan">
                    {hero.nickname.charAt(0).toUpperCase()}
                  </div>
                )}
              </div>
              
              {/* Hero info */}
              <div className="text-center flex-1">
                <h4 className="text-cyprine-cyan font-bold text-sm mb-1 truncate">
                  {hero.nickname}
                </h4>
                <p className="text-gray-300 text-xs truncate">
                  {hero.firstname} {hero.lastname}
                </p>
              </div>

              {/* Fire button */}
              <button
                onClick={() => onRemoveHero(index)}
                className="
                  mt-2 w-full py-1 px-2 bg-red-600 hover:bg-red-500 
                  text-white text-xs font-bold rounded transition-colors duration-200
                  flex items-center justify-center gap-1
                "
                title="Retirer du groupe"
              >
                <svg className="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                </svg>
                Fire
              </button>
            </div>

            {/* Slot number badge */}
            <div className="absolute -top-2 -left-2 w-6 h-6 bg-cyprine-orange rounded-full flex items-center justify-center text-white text-xs font-bold">
              {index + 1}
            </div>
          </>
        ) : (
          <>
            {/* Empty slot */}
            <div className="h-full flex flex-col items-center justify-center p-4 text-gray-500">
              <svg className="w-12 h-12 mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
              </svg>
              <p className="text-xs text-center">
                Glissez un héros ici
              </p>
            </div>

            {/* Slot number badge */}
            <div className="absolute -top-2 -left-2 w-6 h-6 bg-gray-600 rounded-full flex items-center justify-center text-white text-xs font-bold">
              {index + 1}
            </div>
          </>
        )}

        {/* Drop indicator */}
        <div className="absolute inset-0 rounded-lg bg-cyprine-cyan/20 opacity-0 transition-opacity duration-200 pointer-events-none" />
      </div>
    );
  };

  const filledSlots = team.filter(hero => hero !== null).length;
  const teamStrength = team
    .filter(hero => hero !== null)
    .reduce((total, hero) => {
      const skillValues = Object.values(hero!.skills).map(Number);
      const avgSkill = skillValues.length > 0 ? skillValues.reduce((a, b) => a + b, 0) / skillValues.length : 0;
      return total + avgSkill;
    }, 0);

  return (
    <div className="bg-gradient-to-br from-cyprine-darker to-cyprine-dark rounded-lg p-6 border border-gray-700">
      <div className="text-center mb-6">
        <h2 className="text-2xl font-bold text-cyprine-cyan mb-2">
          Composition de l'Équipe
        </h2>
        <div className="flex items-center justify-center gap-4 text-sm text-gray-300">
          <span>
            <span className="text-cyprine-cyan font-bold">{filledSlots}</span>/3 héros
          </span>
          {filledSlots > 0 && (
            <span>
              Force: <span className="text-cyprine-orange font-bold">
                {(teamStrength / filledSlots).toFixed(1)}/5
              </span>
            </span>
          )}
        </div>
      </div>

      {/* Team slots */}
      <div className="flex justify-center gap-6">
        {team.map((hero, index) => (
          <TeamSlot key={index} hero={hero} index={index} />
        ))}
      </div>

      {/* Team status */}
      <div className="mt-6 text-center">
        {filledSlots === 0 && (
          <p className="text-gray-400 italic">
            Votre équipe est vide. Glissez des héros depuis la galerie !
          </p>
        )}
        {filledSlots === 3 && (
          <div className="bg-cyprine-cyan/20 border border-cyprine-cyan/50 rounded-lg p-3">
            <p className="text-cyprine-cyan font-bold">
              🎉 Équipe complète ! Prêts pour l'aventure !
            </p>
          </div>
        )}
      </div>
    </div>
  );
};

export default TeamComposition;