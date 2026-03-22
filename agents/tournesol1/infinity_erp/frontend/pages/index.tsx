import { useEffect } from 'react'
import { useRouter } from 'next/router'
import { useAuth } from '../contexts/AuthContext'
import Dashboard from '../components/Dashboard'
import LoginForm from '../components/LoginForm'
import { CircularProgress, Box } from '@mui/material'

export default function Home() {
  const { user, loading } = useAuth()
  const router = useRouter()

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="100vh">
        <CircularProgress />
      </Box>
    )
  }

  if (!user) {
    return <LoginForm />
  }

  return <Dashboard />
}