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
  IconButton,
  Alert
} from '@mui/material'
import { Add as AddIcon, Edit as EditIcon, Upload as UploadIcon } from '@mui/icons-material'
import { useQuery, useMutation, useQueryClient } from 'react-query'
import { clientService, Client } from '../services/clientService'

const ClientsManager: React.FC = () => {
  const [open, setOpen] = useState(false)
  const [editingClient, setEditingClient] = useState<Client | null>(null)
  const [formData, setFormData] = useState({
    company_name: '',
    contact_person: '',
    email: '',
    phone: '',
    address: '',
    city: '',
    postal_code: '',
    country: 'France'
  })
  const [csvFile, setCsvFile] = useState<File | null>(null)
  const [uploadStatus, setUploadStatus] = useState('')

  const queryClient = useQueryClient()

  const { data: clients, isLoading, error } = useQuery('clients', clientService.getClients)

  const createMutation = useMutation(clientService.createClient, {
    onSuccess: () => {
      queryClient.invalidateQueries('clients')
      setOpen(false)
      resetForm()
    }
  })

  const updateMutation = useMutation(
    ({ id, data }: { id: string; data: any }) => clientService.updateClient(id, data),
    {
      onSuccess: () => {
        queryClient.invalidateQueries('clients')
        setOpen(false)
        resetForm()
      }
    }
  )

  const uploadMutation = useMutation(clientService.uploadCsv, {
    onSuccess: (response) => {
      queryClient.invalidateQueries('clients')
      setUploadStatus(response.message)
      setCsvFile(null)
    },
    onError: (error: any) => {
      setUploadStatus(`Erreur: ${error.response?.data?.detail || 'Upload failed'}`)
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
      country: 'France'
    })
    setEditingClient(null)
  }

  const handleOpen = (client?: Client) => {
    if (client) {
      setEditingClient(client)
      setFormData({
        company_name: client.company_name,
        contact_person: client.contact_person || '',
        email: client.email || '',
        phone: client.phone || '',
        address: client.address || '',
        city: client.city || '',
        postal_code: client.postal_code || '',
        country: client.country
      })
    } else {
      resetForm()
    }
    setOpen(true)
  }

  const handleSubmit = () => {
    if (editingClient) {
      updateMutation.mutate({ id: editingClient.id, data: formData })
    } else {
      createMutation.mutate(formData)
    }
  }

  const handleCsvUpload = () => {
    if (csvFile) {
      uploadMutation.mutate(csvFile)
    }
  }

  if (isLoading) return <div>Chargement...</div>
  if (error) return <div>Erreur lors du chargement</div>

  return (
    <Box>
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Typography variant="h4">Gestion des Clients</Typography>
        <Box>
          <Button
            variant="contained"
            startIcon={<AddIcon />}
            onClick={() => handleOpen()}
            sx={{ mr: 2 }}
          >
            Nouveau Client
          </Button>
          <Button
            variant="outlined"
            startIcon={<UploadIcon />}
            component="label"
          >
            Import CSV
            <input
              type="file"
              accept=".csv"
              hidden
              onChange={(e) => setCsvFile(e.target.files?.[0] || null)}
            />
          </Button>
        </Box>
      </Box>

      {csvFile && (
        <Box mb={2}>
          <Alert severity="info">
            Fichier sélectionné: {csvFile.name}
            <Button onClick={handleCsvUpload} sx={{ ml: 2 }}>
              Upload
            </Button>
          </Alert>
        </Box>
      )}

      {uploadStatus && (
        <Alert severity={uploadStatus.includes('Erreur') ? 'error' : 'success'} sx={{ mb: 2 }}>
          {uploadStatus}
        </Alert>
      )}

      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>Entreprise</TableCell>
              <TableCell>Contact</TableCell>
              <TableCell>Email</TableCell>
              <TableCell>Téléphone</TableCell>
              <TableCell>Ville</TableCell>
              <TableCell>Actions</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {clients?.map((client) => (
              <TableRow key={client.id}>
                <TableCell>{client.company_name}</TableCell>
                <TableCell>{client.contact_person}</TableCell>
                <TableCell>{client.email}</TableCell>
                <TableCell>{client.phone}</TableCell>
                <TableCell>{client.city}</TableCell>
                <TableCell>
                  <IconButton onClick={() => handleOpen(client)}>
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
          {editingClient ? 'Modifier le Client' : 'Nouveau Client'}
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
            label="Adresse"
            fullWidth
            multiline
            rows={2}
            variant="outlined"
            value={formData.address}
            onChange={(e) => setFormData({ ...formData, address: e.target.value })}
          />
          <TextField
            margin="dense"
            label="Ville"
            fullWidth
            variant="outlined"
            value={formData.city}
            onChange={(e) => setFormData({ ...formData, city: e.target.value })}
          />
          <TextField
            margin="dense"
            label="Code postal"
            fullWidth
            variant="outlined"
            value={formData.postal_code}
            onChange={(e) => setFormData({ ...formData, postal_code: e.target.value })}
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpen(false)}>Annuler</Button>
          <Button onClick={handleSubmit} variant="contained">
            {editingClient ? 'Modifier' : 'Créer'}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  )
}

export default ClientsManager