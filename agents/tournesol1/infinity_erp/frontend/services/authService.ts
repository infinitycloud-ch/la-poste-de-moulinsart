import axios from 'axios'

const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:8000'

const api = axios.create({
  baseURL: API_BASE_URL,
})

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token')
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

export interface User {
  id: string
  email: string
  first_name: string
  last_name: string
  role: string
  is_active: boolean
  created_at: string
}

export interface LoginResponse {
  access_token: string
  token_type: string
}

export const authService = {
  async login(email: string, password: string): Promise<LoginResponse> {
    const response = await api.post('/auth/login', { email, password })
    return response.data
  },

  async register(userData: {
    email: string
    password: string
    first_name: string
    last_name: string
    role: string
  }): Promise<User> {
    const response = await api.post('/auth/register', userData)
    return response.data
  },

  async getCurrentUser(): Promise<User> {
    const response = await api.get('/auth/me')
    return response.data
  }
}

export default api