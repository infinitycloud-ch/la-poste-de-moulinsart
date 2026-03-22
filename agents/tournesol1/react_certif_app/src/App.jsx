import { useState, useEffect } from 'react'
import './App.css'

function App() {
  const [s2sState, setS2sState] = useState('idle')
  const [isRecording, setIsRecording] = useState(false)
  const [pulseIntensity, setPulseIntensity] = useState(0)

  // Simulation du pipeline S2S
  const simulateS2SPipeline = () => {
    if (s2sState !== 'idle') return

    setS2sState('listening')
    setIsRecording(true)

    // Phase écoute (3s)
    setTimeout(() => {
      setS2sState('processing')
      setIsRecording(false)
    }, 3000)

    // Phase traitement (2s)
    setTimeout(() => {
      setS2sState('speaking')
    }, 5000)

    // Phase parole (4s)
    setTimeout(() => {
      setS2sState('idle')
    }, 9000)
  }

  // Animation du pulse pour feedback visuel
  useEffect(() => {
    let interval
    if (s2sState === 'listening') {
      interval = setInterval(() => {
        setPulseIntensity(prev => (prev + 0.1) % 1)
      }, 100)
    } else if (s2sState === 'processing') {
      interval = setInterval(() => {
        setPulseIntensity(prev => (prev + 0.2) % 1)
      }, 200)
    } else if (s2sState === 'speaking') {
      interval = setInterval(() => {
        setPulseIntensity(prev => (prev + 0.15) % 1)
      }, 150)
    } else {
      setPulseIntensity(0)
    }

    return () => clearInterval(interval)
  }, [s2sState])

  const getStateColor = () => {
    switch (s2sState) {
      case 'listening': return '#00ff88'
      case 'processing': return '#ffaa00'
      case 'speaking': return '#0088ff'
      default: return '#666666'
    }
  }

  const getStateIcon = () => {
    switch (s2sState) {
      case 'listening': return '🎤'
      case 'processing': return '⚡'
      case 'speaking': return '🔊'
      default: return '💬'
    }
  }

  return (
    <div className="s2s-interface">
      <div className="status-container">
        <div
          className="status-orb"
          style={{
            backgroundColor: getStateColor(),
            transform: `scale(${1 + pulseIntensity * 0.3})`,
            boxShadow: `0 0 ${20 + pulseIntensity * 30}px ${getStateColor()}`
          }}
        >
          <span className="status-icon">{getStateIcon()}</span>
        </div>

        <div className="status-text">
          <h2 className="state-title">
            {s2sState === 'idle' && 'Prêt'}
            {s2sState === 'listening' && 'Écoute...'}
            {s2sState === 'processing' && 'Traitement...'}
            {s2sState === 'speaking' && 'Réponse...'}
          </h2>

          <div className="progress-bar">
            <div
              className="progress-fill"
              style={{
                width: s2sState === 'idle' ? '0%' :
                       s2sState === 'listening' ? '33%' :
                       s2sState === 'processing' ? '66%' : '100%',
                backgroundColor: getStateColor()
              }}
            />
          </div>
        </div>
      </div>

      <button
        className="trigger-btn"
        onClick={simulateS2SPipeline}
        disabled={s2sState !== 'idle'}
        style={{
          backgroundColor: s2sState === 'idle' ? '#00ff88' : '#333',
          cursor: s2sState === 'idle' ? 'pointer' : 'not-allowed'
        }}
      >
        {s2sState === 'idle' ? 'Démarrer S2S' : 'En cours...'}
      </button>
    </div>
  )
}

export default App
