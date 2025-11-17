import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import { FiSearch, FiUser, FiLogOut, FiSettings, FiEdit3 } from 'react-icons/fi'
import './Navbar.css'

const Navbar = () => {
  const { user, logout } = useAuth()
  const navigate = useNavigate()
  const [searchQuery, setSearchQuery] = useState('')

  const handleSearch = (e) => {
    e.preventDefault()
    if (searchQuery.trim()) {
      navigate(`/?search=${encodeURIComponent(searchQuery)}`)
    }
  }

  const handleLogout = () => {
    logout()
    navigate('/')
  }

  return (
    <nav className="navbar">
      <div className="container">
        <div className="navbar-content">
          <Link to="/" className="navbar-brand">
            <h1>DevBlog</h1>
          </Link>

          <form onSubmit={handleSearch} className="navbar-search">
            <input
              type="text"
              placeholder="Поиск статей..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
            />
            <button type="submit">
              <FiSearch />
            </button>
          </form>

          <div className="navbar-actions">
            <Link to="/security-demo" className="btn-demo">Security demo</Link>
            {user ? (
              <>
                {/* Только авторы могут создавать статьи */}
                {(user.role === 'author' || user.role === 'admin') && (
                  <>
                    <Link to="/create-article" className="btn-create">
                      <FiEdit3 /> Создать статью
                    </Link>
                    <Link to="/author-dashboard" className="btn-dashboard">
                      <FiSettings /> Панель автора
                    </Link>
                  </>
                )}
                {user.role === 'admin' && (
                  <Link to="/admin" className="btn-admin">
                    <FiSettings /> Админ-панель
                  </Link>
                )}
                <Link to={`/user/${user.id}`} className="navbar-user">
                  {user.avatar ? (
                    <img src={user.avatar} alt={user.username} />
                  ) : (
                    <FiUser />
                  )}
                  <span>{user.username}</span>
                </Link>
                <button onClick={handleLogout} className="btn-logout">
                  <FiLogOut />
                </button>
              </>
            ) : (
              <>
                <Link to="/login" className="btn-login">Войти</Link>
                <Link to="/register" className="btn-register">Регистрация</Link>
              </>
            )}
          </div>
        </div>
      </div>
    </nav>
  )
}

export default Navbar

