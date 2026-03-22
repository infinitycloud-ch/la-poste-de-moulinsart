import api from './authService'

export interface Supplier {
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
  payment_terms: number
  is_active: boolean
  created_at: string
}

export interface SupplierCreate {
  company_name: string
  contact_person?: string
  email?: string
  phone?: string
  address?: string
  city?: string
  postal_code?: string
  country?: string
  tax_number?: string
  payment_terms?: number
}

export const supplierService = {
  async getSuppliers(): Promise<Supplier[]> {
    const response = await api.get('/suppliers')
    return response.data
  },

  async createSupplier(supplierData: SupplierCreate): Promise<Supplier> {
    const response = await api.post('/suppliers', supplierData)
    return response.data
  }
}