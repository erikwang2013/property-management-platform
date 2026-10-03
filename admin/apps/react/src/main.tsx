// Copyright (c) 2026 erik <erik@erik.xyz> — https://erik.xyz

import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import App from './App'
import AppProviders from './AppProviders'
import './index.css'

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <AppProviders>
      <App />
    </AppProviders>
  </StrictMode>,
)
