import api from './authService'

export interface Client {
  id: string
  company_name: string
  contact_person?: string
  email?: string
  phone?: string
  address?: string
  city?: string
  postal_code?: string
  country: string
  tax_number?: string
  is_active: boolean
  created_at: string
}

export interface ClientCreate {
  company_name: string
  contact_person?: string
  email?: string
  phone?: string
  address?: string
  city?: string
  postal_code?: string
  country?: string
  tax_number?: string
}

export const clientService = {
  async getClients(): Promise<Client[]> {
    const response = await api.get('/clients')
    return response.data
  },

  async createClient(clientData: ClientCreate): Promise<Client> {
    const response = await api.post('/clients', clientData)
    return response.data
  },

  async updateClient(id: string, clientData: Partial<ClientCreate>): Promise<Client> {
    const response = await api.put(`/clients/${id}`, clientData)
    return response.data
  },

  async deleteClient(id: string): Promise<void> {
    await api.delete(`/clients/${id}`)
  },

  async uploadCsv(file: File): Promise<{ message: string }> {
    const formData = new FormData()
    formData.append('file', file)
    const response = await api.post('/clients/import-csv', formData, {
      headers: {
        'Content-Type': 'multipart/form-data'
      }
    })
    return response.data
  }
}