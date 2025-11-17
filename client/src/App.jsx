import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom'
import { Toaster } from 'react-hot-toast'
import { AuthProvider } from './context/AuthContext'
import Navbar from './components/Navbar'
import Home from './pages/Home'
import Article from './pages/Article'
import CreateArticle from './pages/CreateArticle'
import EditArticle from './pages/EditArticle'
import Profile from './pages/Profile'
import Login from './pages/Login'
import Register from './pages/Register'
import ForgotPassword from './pages/ForgotPassword'
import ResetPassword from './pages/ResetPassword'
import AdminPanel from './pages/AdminPanel'
import AuthorDashboard from './pages/AuthorDashboard'
import SecurityDemo from './pages/SecurityDemo'
import ProtectedRoute from './components/ProtectedRoute'
import './App.css'

function App() {
  return (
    <AuthProvider>
      <Router>
        <div className="App">
          <Navbar />
          <main className="main-content">
            <Routes>
              <Route path="/" element={<Home />} />
              <Route path="/article/:slug" element={<Article />} />
              <Route path="/user/:id" element={<Profile />} />
              <Route path="/login" element={<Login />} />
              <Route path="/register" element={<Register />} />
              <Route path="/forgot-password" element={<ForgotPassword />} />
              <Route path="/reset-password/:token" element={<ResetPassword />} />
              <Route path="/security-demo" element={<SecurityDemo />} />
              <Route
                path="/create-article"
                element={
                  <ProtectedRoute requiredRole="author">
                    <CreateArticle />
                  </ProtectedRoute>
                }
              />
              <Route
                path="/edit-article/:id"
                element={
                  <ProtectedRoute requiredRole="author">
                    <EditArticle />
                  </ProtectedRoute>
                }
              />
              <Route
                path="/author-dashboard"
                element={
                  <ProtectedRoute requiredRole="author">
                    <AuthorDashboard />
                  </ProtectedRoute>
                }
              />
              <Route
                path="/admin"
                element={
                  <ProtectedRoute requiredRole="admin">
                    <AdminPanel />
                  </ProtectedRoute>
                }
              />
              <Route path="*" element={<Navigate to="/" replace />} />
            </Routes>
          </main>
          <Toaster position="top-right" />
        </div>
      </Router>
    </AuthProvider>
  )
}

export default App

