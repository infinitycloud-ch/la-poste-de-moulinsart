import React, { useState } from 'react'
import {
  AppBar,
  Toolbar,
  Typography,
  Button,
  Container,
  Grid,
  Card,
  CardContent,
  CardActions,
  Box,
  Drawer,
  List,
  ListItem,
  ListItemIcon,
  ListItemText,
  IconButton
} from '@mui/material'
import {
  Menu as MenuIcon,
  People as PeopleIcon,
  Business as BusinessIcon,
  Dashboard as DashboardIcon,
  ExitToApp as LogoutIcon
} from '@mui/icons-material'
import { useAuth } from '../contexts/AuthContext'
import ClientsManager from './ClientsManager'
import SuppliersManager from './SuppliersManager'

const Dashboard: React.FC = () => {
  const { user, logout } = useAuth()
  const [activeView, setActiveView] = useState('dashboard')
  const [drawerOpen, setDrawerOpen] = useState(false)

  const menuItems = [
    { id: 'dashboard', label: 'Tableau de bord', icon: <DashboardIcon /> },
    { id: 'clients', label: 'Clients', icon: <PeopleIcon /> },
    { id: 'suppliers', label: 'Fournisseurs', icon: <BusinessIcon /> },
  ]

  const renderContent = () => {
    switch (activeView) {
      case 'clients':
        return <ClientsManager />
      case 'suppliers':
        return <SuppliersManager />
      default:
        return (
          <Grid container spacing={3}>
            <Grid item xs={12} md={4}>
              <Card>
                <CardContent>
                  <Typography variant="h5" component="div">
                    Clients
                  </Typography>
                  <Typography variant="body2">
                    Gérer vos clients et contacts
                  </Typography>
                </CardContent>
                <CardActions>
                  <Button size="small" onClick={() => setActiveView('clients')}>
                    Accéder
                  </Button>
                </CardActions>
              </Card>
            </Grid>
            <Grid item xs={12} md={4}>
              <Card>
                <CardContent>
                  <Typography variant="h5" component="div">
                    Fournisseurs
                  </Typography>
                  <Typography variant="body2">
                    Gérer vos fournisseurs
                  </Typography>
                </CardContent>
                <CardActions>
                  <Button size="small" onClick={() => setActiveView('suppliers')}>
                    Accéder
                  </Button>
                </CardActions>
              </Card>
            </Grid>
            <Grid item xs={12} md={4}>
              <Card>
                <CardContent>
                  <Typography variant="h5" component="div">
                    Rapports
                  </Typography>
                  <Typography variant="body2">
                    Analytics et rapports
                  </Typography>
                </CardContent>
                <CardActions>
                  <Button size="small">Bientôt</Button>
                </CardActions>
              </Card>
            </Grid>
          </Grid>
        )
    }
  }

  return (
    <Box sx={{ flexGrow: 1 }}>
      <AppBar position="static">
        <Toolbar>
          <IconButton
            size="large"
            edge="start"
            color="inherit"
            aria-label="menu"
            sx={{ mr: 2 }}
            onClick={() => setDrawerOpen(true)}
          >
            <MenuIcon />
          </IconButton>
          <Typography variant="h6" component="div" sx={{ flexGrow: 1 }}>
            INFINITY ERP - {user?.first_name} {user?.last_name} ({user?.role})
          </Typography>
          <Button color="inherit" onClick={logout} startIcon={<LogoutIcon />}>
            Déconnexion
          </Button>
        </Toolbar>
      </AppBar>

      <Drawer
        anchor="left"
        open={drawerOpen}
        onClose={() => setDrawerOpen(false)}
      >
        <Box sx={{ width: 250 }}>
          <List>
            {menuItems.map((item) => (
              <ListItem
                button
                key={item.id}
                onClick={() => {
                  setActiveView(item.id)
                  setDrawerOpen(false)
                }}
              >
                <ListItemIcon>{item.icon}</ListItemIcon>
                <ListItemText primary={item.label} />
              </ListItem>
            ))}
          </List>
        </Box>
      </Drawer>

      <Container maxWidth="lg" sx={{ mt: 4, mb: 4 }}>
        {renderContent()}
      </Container>
    </Box>
  )
}

export default Dashboard