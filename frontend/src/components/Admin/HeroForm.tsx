import React, { useState, useEffect } from 'react';
import { Hero, HeroCreate, HeroUpdate, heroesApi } from '../../services/api';

interface HeroFormProps {
  hero?: Hero;
  onSave: (hero: Hero) => void;
  onCancel: () => void;
}

const HeroForm: React.FC<HeroFormProps> = ({ hero, onSave, onCancel }) => {
  const [formData, setFormData] = useState<HeroCreate>({
    firstname: '',
    lastname: '',
    nickname: '',
    description: '',
    profile_picture: '',
    skills: {}
  });
  const [skills, setSkills] = useState<Array<{ name: string; level: number }>>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [imageFile, setImageFile] = useState<File | null>(null);
  const [previewUrl, setPreviewUrl] = useState<string>('');

  useEffect(() => {
    if (hero) {
      setFormData({
        firstname: hero.firstname,
        lastname: hero.lastname,
        nickname: hero.nickname,
        description: hero.description,
        profile_picture: hero.profile_picture || '',
        skills: hero.skills
      });
      
      // Convert skills object to array for form
      const skillsArray = Object.entries(hero.skills).map(([name, level]) => ({
        name,
        level: Number(level)
      }));
      setSkills(skillsArray);

      if (hero.profile_picture) {
        setPreviewUrl(`http://localhost:8000${hero.profile_picture}`);
      }
    }
  }, [hero]);

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
  };

  const handleImageChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      setImageFile(file);
      const url = URL.createObjectURL(file);
      setPreviewUrl(url);
    }
  };

  const addSkill = () => {
    setSkills(prev => [...prev, { name: '', level: 1 }]);
  };

  const updateSkill = (index: number, field: 'name' | 'level', value: string | number) => {
    setSkills(prev => prev.map((skill, i) => 
      i === index ? { ...skill, [field]: value } : skill
    ));
  };

  const removeSkill = (index: number) => {
    setSkills(prev => prev.filter((_, i) => i !== index));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    try {
      // Convert skills array to object
      const skillsObject = skills.reduce((acc, skill) => {
        if (skill.name.trim()) {
          acc[skill.name.trim()] = skill.level;
        }
        return acc;
      }, {} as Record<string, number>);

      const heroData = { ...formData, skills: skillsObject };

      let savedHero: Hero;
      if (hero) {
        // Update existing hero
        const response = await heroesApi.update(hero.id, heroData as HeroUpdate);
        savedHero = response.data;
      } else {
        // Create new hero
        const response = await heroesApi.create(heroData);
        savedHero = response.data;
      }

      // Upload image if provided
      if (imageFile) {
        await heroesApi.uploadImage(savedHero.id, imageFile);
        // Refresh hero data to get updated image URL
        const updatedResponse = await heroesApi.getById(savedHero.id);
        savedHero = updatedResponse.data;
      }

      onSave(savedHero);
    } catch (err: any) {
      console.error('Failed to save hero:', err);
      if (err.response?.data?.detail) {
        setError(err.response.data.detail);
      } else {
        setError('Erreur lors de la sauvegarde du héros');
      }
    } finally {
      setLoading(false);
    }
  };

  const characterCount = formData.description.length;
  const maxChars = 3000; // Augmenté de 1000 à 3000 caractères

  return (
    <div className="bg-gradient-to-br from-cyprine-darker to-cyprine-dark p-6 rounded-lg border border-gray-700">
      <div className="flex items-center justify-between mb-6">
        <h2 className="text-2xl font-bold text-cyprine-cyan">
          {hero ? 'Modifier le héros' : 'Nouveau héros'}
        </h2>
        <button
          onClick={onCancel}
          className="text-gray-400 hover:text-white transition-colors"
        >
          <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>
      </div>

      <form onSubmit={handleSubmit} className="space-y-6">
        {/* Basic Info */}
        <div className="grid grid-cols-2 gap-4">
          <div>
            <label htmlFor="firstname" className="block text-sm font-medium text-gray-300 mb-2">
              Prénom *
            </label>
            <input
              type="text"
              id="firstname"
              name="firstname"
              value={formData.firstname}
              onChange={handleInputChange}
              className="w-full px-3 py-2 bg-cyprine-darker border border-gray-600 rounded-lg text-white focus:outline-none focus:border-cyprine-cyan"
              required
            />
          </div>
          <div>
            <label htmlFor="lastname" className="block text-sm font-medium text-gray-300 mb-2">
              Nom *
            </label>
            <input
              type="text"
              id="lastname"
              name="lastname"
              value={formData.lastname}
              onChange={handleInputChange}
              className="w-full px-3 py-2 bg-cyprine-darker border border-gray-600 rounded-lg text-white focus:outline-none focus:border-cyprine-cyan"
              required
            />
          </div>
        </div>

        <div>
          <label htmlFor="nickname" className="block text-sm font-medium text-gray-300 mb-2">
            Surnom *
          </label>
          <input
            type="text"
            id="nickname"
            name="nickname"
            value={formData.nickname}
            onChange={handleInputChange}
            className="w-full px-3 py-2 bg-cyprine-darker border border-gray-600 rounded-lg text-white focus:outline-none focus:border-cyprine-cyan"
            required
          />
        </div>

        {/* Description */}
        <div>
          <label htmlFor="description" className="block text-sm font-medium text-gray-300 mb-2">
            Description *
          </label>
          <textarea
            id="description"
            name="description"
            value={formData.description}
            onChange={handleInputChange}
            rows={8}
            maxLength={maxChars}
            className="w-full px-4 py-3 bg-cyprine-darker border border-gray-600 rounded-lg text-white focus:outline-none focus:border-cyprine-cyan resize-vertical min-h-[200px] leading-relaxed"
            placeholder="Décrivez la personnalité, l'histoire et les traits du héros...&#10;&#10;Vous pouvez inclure :&#10;• Son origine et son passé&#10;• Ses motivations et objectifs&#10;• Sa personnalité et ses traits&#10;• Ses relations avec d'autres héros"
            required
          />
          <div className="text-right text-sm text-gray-400 mt-1">
            {characterCount}/{maxChars} caractères
          </div>
        </div>

        {/* Profile Picture */}
        <div>
          <label htmlFor="image" className="block text-sm font-medium text-gray-300 mb-2">
            Photo de profil
          </label>
          <div className="flex items-start gap-4">
            {previewUrl && (
              <div className="w-24 h-24 rounded-lg overflow-hidden bg-gray-800 border border-gray-600">
                <img src={previewUrl} alt="Aperçu" className="w-full h-full object-cover" />
              </div>
            )}
            <input
              type="file"
              id="image"
              accept="image/*"
              onChange={handleImageChange}
              className="flex-1 px-3 py-2 bg-cyprine-darker border border-gray-600 rounded-lg text-white focus:outline-none focus:border-cyprine-cyan file:mr-3 file:py-1 file:px-3 file:rounded file:border-0 file:bg-cyprine-cyan file:text-cyprine-dark file:font-medium"
            />
          </div>
        </div>

        {/* Skills */}
        <div>
          <div className="flex items-center justify-between mb-3">
            <label className="block text-sm font-medium text-gray-300">Compétences</label>
            <button
              type="button"
              onClick={addSkill}
              className="px-3 py-1 bg-cyprine-cyan text-cyprine-dark text-sm font-medium rounded hover:bg-cyprine-cyan/80 transition-colors"
            >
              + Ajouter
            </button>
          </div>
          <div className="space-y-3">
            {skills.map((skill, index) => (
              <div key={index} className="flex items-center gap-3 p-3 bg-cyprine-darker/50 rounded-lg border border-gray-600">
                <input
                  type="text"
                  value={skill.name}
                  onChange={(e) => updateSkill(index, 'name', e.target.value)}
                  placeholder="Nom de la compétence"
                  className="flex-1 px-2 py-1 bg-cyprine-darker border border-gray-600 rounded text-white text-sm focus:outline-none focus:border-cyprine-cyan"
                />
                <div className="flex items-center gap-2">
                  <input
                    type="range"
                    min="1"
                    max="5"
                    value={skill.level}
                    onChange={(e) => updateSkill(index, 'level', Number(e.target.value))}
                    className="w-20"
                  />
                  <span className="text-cyprine-cyan font-bold w-8 text-center">{skill.level}/5</span>
                </div>
                <button
                  type="button"
                  onClick={() => removeSkill(index)}
                  className="text-red-400 hover:text-red-300 transition-colors"
                >
                  <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                  </svg>
                </button>
              </div>
            ))}
          </div>
        </div>

        {error && (
          <div className="bg-red-900/20 border border-red-500/50 rounded-lg p-3">
            <p className="text-red-400 text-sm">{error}</p>
          </div>
        )}

        {/* Submit buttons */}
        <div className="flex gap-3 pt-4">
          <button
            type="submit"
            disabled={loading}
            className="flex-1 py-3 px-4 bg-cyprine-cyan hover:bg-cyprine-cyan/80 text-cyprine-dark font-bold rounded-lg transition-colors disabled:opacity-50"
          >
            {loading ? 'Sauvegarde...' : (hero ? 'Modifier' : 'Créer')}
          </button>
          <button
            type="button"
            onClick={onCancel}
            className="px-6 py-3 bg-gray-600 hover:bg-gray-500 text-white font-medium rounded-lg transition-colors"
          >
            Annuler
          </button>
        </div>
      </form>
    </div>
  );
};

export default HeroForm;