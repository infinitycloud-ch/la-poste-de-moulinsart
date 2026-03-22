import React, { useState } from 'react'
import {
  Box,
  Button,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  Typography,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  IconButton
} from '@mui/material'
import { Add as AddIcon, Edit as EditIcon } from '@mui/icons-material'
import { useQuery, useMutation, useQueryClient } from 'react-query'
import { supplierService, Supplier } from '../services/supplierService'

const SuppliersManager: React.FC = () => {
  const [open, setOpen] = useState(false)
  const [editingSupplier, setEditingSupplier] = useState<Supplier | null>(null)
  const [formData, setFormData] = useState({
    company_name: '',
    contact_person: '',
    email: '',
    phone: '',
    address: '',
    city: '',
    postal_code: '',
    country: 'France',
    payment_terms: 30
  })

  const queryClient = useQueryClient()

  const { data: suppliers, isLoading, error } = useQuery('suppliers', supplierService.getSuppliers)

  const createMutation = useMutation(supplierService.createSupplier, {
    onSuccess: () => {
      queryClient.invalidateQueries('suppliers')
      setOpen(false)
      resetForm()
    }
  })

  const resetForm = () => {
    setFormData({
      company_name: '',
      contact_person: '',
      email: '',
      phone: '',
      address: '',
      city: '',
      postal_code: '',
      country: 'France',
      payment_terms: 30
    })
    setEditingSupplier(null)
  }

  const handleOpen = (supplier?: Supplier) => {
    if (supplier) {
      setEditingSupplier(supplier)
      setFormData({
        company_name: supplier.company_name,
        contact_person: supplier.contact_person || '',
        email: supplier.email || '',
        phone: supplier.phone || '',
        address: supplier.address || '',
        city: supplier.city || '',
        postal_code: supplier.postal_code || '',
        country: supplier.country,
        payment_terms: supplier.payment_terms
      })
    } else {
      resetForm()
    }
    setOpen(true)
  }

  const handleSubmit = () => {
    createMutation.mutate(formData)
  }

  if (isLoading) return <div>Chargement...</div>
  if (error) return <div>Erreur lors du chargement</div>

  return (
    <Box>
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Typography variant="h4">Gestion des Fournisseurs</Typography>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => handleOpen()}
        >
          Nouveau Fournisseur
        </Button>
      </Box>

      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>Entreprise</TableCell>
              <TableCell>Contact</TableCell>
              <TableCell>Email</TableCell>
              <TableCell>Téléphone</TableCell>
              <TableCell>Ville</TableCell>
              <TableCell>Délai de paiement</TableCell>
              <TableCell>Actions</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {suppliers?.map((supplier) => (
              <TableRow key={supplier.id}>
                <TableCell>{supplier.company_name}</TableCell>
                <TableCell>{supplier.contact_person}</TableCell>
                <TableCell>{supplier.email}</TableCell>
                <TableCell>{supplier.phone}</TableCell>
                <TableCell>{supplier.city}</TableCell>
                <TableCell>{supplier.payment_terms} jours</TableCell>
                <TableCell>
                  <IconButton onClick={() => handleOpen(supplier)}>
                    <EditIcon />
                  </IconButton>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </TableContainer>

      <Dialog open={open} onClose={() => setOpen(false)} maxWidth="md" fullWidth>
        <DialogTitle>
          {editingSupplier ? 'Modifier le Fournisseur' : 'Nouveau Fournisseur'}
        </DialogTitle>
        <DialogContent>
          <TextField
            margin="dense"
            label="Nom de l'entreprise"
            fullWidth
            variant="outlined"
            value={formData.company_name}
            onChange={(e) => setFormData({ ...formData, company_name: e.target.value })}
          />
          <TextField
            margin="dense"
            label="Personne de contact"
            fullWidth
            variant="outlined"
            value={formData.contact_person}
            onChange={(e) => setFormData({ ...formData, contact_person: e.target.value })}
          />
          <TextField
            margin="dense"
            label="Email"
            type="email"
            fullWidth
            variant="outlined"
            value={formData.email}
            onChange={(e) => setFormData({ ...formData, email: e.target.value })}
          />
          <TextField
            margin="dense"
            label="Téléphone"
            fullWidth
            variant="outlined"
            value={formData.phone}
            onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
          />
          <TextField
            margin="dense"
            label="Délai de paiement (jours)"
            type="number"
            fullWidth
            variant="outlined"
            value={formData.payment_terms}
            onChange={(e) => setFormData({ ...formData, payment_terms: parseInt(e.target.value) })}
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpen(false)}>Annuler</Button>
          <Button onClick={handleSubmit} variant="contained">
            {editingSupplier ? 'Modifier' : 'Créer'}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  )
}

export default SuppliersManager