import { useState, useEffect } from 'react'
import { useParams, Link } from 'react-router-dom'
import axios from 'axios'
import { useAuth } from '../context/AuthContext'
import { FiUser, FiHeart, FiEdit2 } from 'react-icons/fi'
import toast from 'react-hot-toast'
import './Profile.css'

const Profile = () => {
  const { id } = useParams()
  const { user: currentUser } = useAuth()
  const [profile, setProfile] = useState(null)
  const [articles, setArticles] = useState([])
  const [subscribed, setSubscribed] = useState(false)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetchProfile()
  }, [id])

  useEffect(() => {
    if (profile && currentUser && currentUser.id !== profile.id) {
      checkSubscription()
    }
  }, [profile, currentUser])

  const fetchProfile = async () => {
    try {
      const response = await axios.get(`/api/users/${id}`)
      setProfile(response.data)
      setArticles(response.data.articles || [])
    } catch (error) {
      console.error('Ошибка загрузки профиля:', error)
      toast.error('Профиль не найден')
    } finally {
      setLoading(false)
    }
  }

  const checkSubscription = async () => {
    try {
      const response = await axios.get(`/api/subscriptions/${id}/check`)
      setSubscribed(response.data.subscribed)
    } catch (error) {
      console.error('Ошибка проверки подписки:', error)
    }
  }

  const handleSubscribe = async () => {
    if (!currentUser) {
      toast.error('Войдите, чтобы подписаться')
      return
    }
    try {
      if (subscribed) {
        await axios.delete(`/api/subscriptions/${id}`)
        setSubscribed(false)
        toast.success('Подписка отменена')
      } else {
        await axios.post(`/api/subscriptions/${id}`)
        setSubscribed(true)
        toast.success('Подписка оформлена')
      }
    } catch (error) {
      toast.error('Ошибка подписки')
    }
  }

  if (loading) {
    return <div className="loading">Загрузка профиля...</div>
  }

  if (!profile) {
    return <div className="no-profile">Профиль не найден</div>
  }

  const isOwnProfile = currentUser && currentUser.id === parseInt(id)

  return (
    <div className="profile-page">
      <div className="container">
        <div className="profile-header">
          <div className="profile-avatar">
            {profile.avatar ? (
              <img src={profile.avatar} alt={profile.username} />
            ) : (
              <FiUser />
            )}
          </div>
          <div className="profile-info">
            <h1>{profile.username}</h1>
            {profile.bio && <p className="profile-bio">{profile.bio}</p>}
            <div className="profile-stats">
              <span>{articles.length} статей</span>
            </div>
          </div>
          {!isOwnProfile && currentUser && (
            <button
              onClick={handleSubscribe}
              className={`btn-subscribe ${subscribed ? 'subscribed' : ''}`}
            >
              <FiHeart /> {subscribed ? 'Подписан' : 'Подписаться'}
            </button>
          )}
        </div>

        <div className="profile-articles">
          <h2>Статьи автора</h2>
          {articles.length === 0 ? (
            <p className="no-articles">Статьи не найдены</p>
          ) : (
            <div className="articles-grid">
              {articles.map((article) => (
                <div key={article.id} className="article-card-small">
                  {article.coverImage && (
                    <div className="article-cover-small">
                      <img
                        src={article.coverImage}
                        alt={article.title}
                      />
                    </div>
                  )}
                  <div className="article-content-small">
                    <h3>
                      <Link to={`/article/${article.slug}`}>{article.title}</Link>
                    </h3>
                    <div className="article-meta-small">
                      <span>{new Date(article.createdAt).toLocaleDateString('ru-RU')}</span>
                      <span>{article.views} просмотров</span>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}

export default Profile

