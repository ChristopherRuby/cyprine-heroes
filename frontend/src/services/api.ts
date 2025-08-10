import axios from 'axios';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000/api';

export interface Hero {
  id: string;
  firstname: string;
  lastname: string;
  nickname: string;
  description: string;
  profile_picture?: string;
  skills: Record<string, number>;
  created_at: string;
  updated_at?: string;
}

export interface HeroCreate {
  firstname: string;
  lastname: string;
  nickname: string;
  description: string;
  profile_picture?: string;
  skills: Record<string, number>;
}

export interface HeroUpdate extends Partial<HeroCreate> {}

export interface LoginRequest {
  password: string;
}

export interface TokenResponse {
  access_token: string;
  token_type: string;
}

const api = axios.create({
  baseURL: API_BASE_URL,
});

// Add auth token to requests if available
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('auth_token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Heroes API
export const heroesApi = {
  getAll: () => api.get<Hero[]>('/heroes'),
  getById: (id: string) => api.get<Hero>(`/heroes/${id}`),
  create: (hero: HeroCreate) => api.post<Hero>('/heroes', hero),
  update: (id: string, hero: HeroUpdate) => api.put<Hero>(`/heroes/${id}`, hero),
  delete: (id: string) => api.delete(`/heroes/${id}`),
  uploadImage: (heroId: string, file: File) => {
    const formData = new FormData();
    formData.append('file', file);
    return api.post(`/heroes/upload-image/${heroId}`, formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
    });
  },
};

// Auth API
export const authApi = {
  login: (credentials: LoginRequest) => api.post<TokenResponse>('/auth/login', credentials),
};

export default api;