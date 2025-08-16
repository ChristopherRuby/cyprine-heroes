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
  const filledSlots = team.filter(hero => hero !== null).length;
  const isTeamComplete = filledSlots === 3;
  
  const TeamSlot: React.FC<{ hero: Hero | null; index: number }> = ({ hero, index }) => {
    const handleDrop = (e: React.DragEvent) => {
      onDrop(e, index);
    };

    return (
      <div className="flex flex-col items-center">
        <div
          className={`
            relative h-60 w-44 rounded-lg border-2 border-dashed transition-all duration-500
            ${hero 
              ? `${isTeamComplete ? 'team-slot-complete' : 'border-cyprine-cyan'} bg-gradient-to-b from-cyprine-darker to-cyprine-dark shadow-lg ${isTeamComplete ? '' : 'shadow-cyprine-cyan/30'}` 
              : 'border-gray-600 bg-cyprine-darker/30 hover:border-cyprine-cyan/50 hover:bg-cyprine-darker/50'
            }
          `}
          onDragOver={onDragOver}
          onDrop={handleDrop}
        >
          {/* Flame particles for complete team */}
          {isTeamComplete && hero && (
            <div className="flame-particles" />
          )}
          
          {hero ? (
            <>
              {/* Hero in slot */}
              <div className="p-4 h-full flex flex-col">
                {/* Profile picture */}
                <div className={`w-24 h-24 mx-auto mb-3 rounded-full overflow-hidden bg-gray-800 border-2 transition-all duration-500 ${
                  isTeamComplete ? 'border-yellow-400 shadow-lg shadow-yellow-400/50' : 'border-cyprine-cyan'
                }`}>
                  {hero.profile_picture ? (
                    <img
                      src={`http://localhost:8000${hero.profile_picture}`}
                      alt={hero.nickname}
                      className="hero-img hero-img--xs"
                    />
                  ) : (
                    <div className={`w-full h-full flex items-center justify-center text-2xl font-bold transition-colors duration-500 ${
                      isTeamComplete ? 'text-yellow-400' : 'text-cyprine-cyan'
                    }`}>
                      {hero.nickname.charAt(0).toUpperCase()}
                    </div>
                  )}
                </div>
                
                {/* Hero info */}
                <div className="text-center flex-1">
                  <h4 className={`font-bold text-base mb-2 truncate transition-colors duration-500 ${
                    isTeamComplete ? 'text-yellow-400' : 'text-cyprine-cyan'
                  }`}>
                    {hero.nickname}
                  </h4>
                  <p className="text-gray-300 text-sm truncate">
                    {hero.firstname} {hero.lastname}
                  </p>
                </div>
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
                <svg className="w-16 h-16 mb-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
                </svg>
                <p className="text-sm text-center">
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

        {/* Remove button - more visible but discreet */}
        {hero && (
          <button
            onClick={() => onRemoveHero(index)}
            className="
              mt-2 w-8 h-8 rounded-full bg-red-500/90 hover:bg-red-500 
              text-white transition-all duration-200 opacity-85 hover:opacity-100
              flex items-center justify-center hover:scale-110 shadow-lg
              border border-red-400/50 hover:border-red-300
            "
            title="Retirer du groupe"
          >
            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={2.5}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        )}
      </div>
    );
  };

  const teamStrength = team
    .filter(hero => hero !== null)
    .reduce((total, hero) => {
      const skillValues = Object.values(hero!.skills).map(Number);
      const avgSkill = skillValues.length > 0 ? skillValues.reduce((a, b) => a + b, 0) / skillValues.length : 0;
      return total + avgSkill;
    }, 0);

  return (
    <div className={`
      rounded-lg p-6 border transition-all duration-1000
      ${isTeamComplete 
        ? 'team-complete border-yellow-400 shadow-2xl shadow-yellow-400/30' 
        : 'bg-gradient-to-br from-cyprine-darker to-cyprine-dark border-gray-700'
      }
    `}>
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
      <div className="flex justify-center gap-8 mb-2">
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
          <div className={`
            rounded-lg p-4 border-2 transition-all duration-1000
            ${isTeamComplete 
              ? 'bg-gradient-to-r from-yellow-500/20 to-orange-500/20 border-yellow-400 shadow-lg shadow-yellow-400/50' 
              : 'bg-cyprine-cyan/20 border-cyprine-cyan/50'
            }
          `}>
            <p className={`font-bold text-lg transition-all duration-1000 ${
              isTeamComplete ? 'team-complete-text' : 'text-cyprine-cyan'
            }`}>
              🔥 Équipe légendaire ! Les flammes de la victoire brûlent ! 🔥
            </p>
          </div>
        )}
      </div>
    </div>
  );
};

export default TeamComposition;